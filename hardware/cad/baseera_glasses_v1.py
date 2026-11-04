"""Baseera glasses: first 3D design (v1).

Builds the printable PETG parts and simple models of the electronics, checks
that no two parts collide, and writes:

  out/stl/*.stl              printable parts, one file each
  out/baseera_glasses.step   the whole assembly, electronics included
  out/model.json             meshes for the 3D viewer (make_viewer.py)

Layout: the right housing holds the XIAO ESP32S3 Sense with its camera looking
ahead, the push button, the vibration motor, the amplifier and the speaker
(grille on the inner side, towards the ear). The left housing holds both
distance sensors (one looking ahead, one 60 degrees down at the floor about a
metre ahead), the power switch and the battery. Wires cross in a groove at the
back of the brow. Temples are screwed to the frame (no hinge) so the wires
never bend.

Electronics sizes are typical datasheet/breakout sizes: measure the parts you
have and change the numbers below before printing.

Axes: X = wearer's right, Y = forward (where the wearer looks), Z = up. mm.
Run: python baseera_glasses.py
"""

import base64
import json
import math
import os
from pathlib import Path

import cadquery as cq
import numpy as np

OUT = Path(__file__).resolve().parent / "out"

# --- frame front ---------------------------------------------------------------
LENS_W, LENS_H, LENS_R = 52.0, 38.0, 11.0
BRIDGE = 14.0
LCX = BRIDGE / 2 + LENS_W / 2            # lens centre, |X|
RIM = 5.5
FRONT_Y, FRONT_T = 3.0, 6.0              # front face at Y=3, back face at Y=-3
FRAME_X = LCX + LENS_W / 2 + RIM         # outer edge of the rims
BROW_Z = (12.0, 27.0)
END_X = 68.0                             # end pieces; inner face of the housings
TAB = ((60.0, END_X), (-10.0, FRONT_Y), (8.0, 22.0))   # end piece the temple screws to
GROOVE = ((-66.0, 66.0), (-3.5, -0.5), (22.0, 25.0))   # wire groove, back of the brow

# --- side housings (built on the right, mirrored for the left) -----------------
WALL = 1.6
H_X = (END_X, 88.0)                      # open on the outer side; the lid closes it
H_Y = (-54.0, 7.0)
H_Z = (-6.0, 28.0)
H_R = 4.0                                # edge rounding seen from the side
CH_DEPTH = 14.0                          # bottom-front chamfer, depth along Y
DOWN_DEG = 60.0                          # chamfer faces this far below horizontal
LID_T = 1.6
POST_D, POST_LEN = 4.0, 3.5              # lid screw posts (M2 self-tapping)
CX = (H_X[0] + WALL + H_X[1]) / 2        # middle of the housing's inside, X
IN_Y = (H_Y[0] + WALL, H_Y[1] - WALL)
IN_Z = (H_Z[0] + WALL, H_Z[1] - WALL)
_P = POST_D / 2 - 0.5                    # posts sit into the corner walls
POSTS = [(IN_Y[0] + _P, IN_Z[1] - _P),   # (Y, Z): back top
         (IN_Y[0] + _P, IN_Z[0] + _P),   # back bottom
         (IN_Y[1] - _P, IN_Z[1] - _P)]   # front top

# --- temples --------------------------------------------------------------------
TEMPLE_T = 4.5
TEMPLE_Z = (10.0, 17.0)
TEMPLE_STRAIGHT_TO = -105.0
TEMPLE_BEND_R, TEMPLE_BEND_DEG, TEMPLE_TAIL = 45.0, 40.0, 10.0

# --- electronics (typical sizes) ------------------------------------------------
XIAO_W, XIAO_H = 17.8, 21.0              # board, X by Z (it faces forward)
XIAO_Z0 = 0.5                            # bottom edge of the boards
TOF_W, TOF_H = 18.0, 13.0                # VL53L1X breakout
AMP_W, AMP_H = 17.8, 19.3                # MAX98357A breakout
SPEAKER_D, SPEAKER_T = 20.0, 4.5
MOTOR_D, MOTOR_T = 10.0, 2.7
BATTERY = (8.0, 40.0, 25.0)              # 802540 LiPo: X, Y, Z


# ---------------------------------------------------------------- helpers

def box(x, y, z):
    (x0, x1), (y0, y1), (z0, z1) = x, y, z
    return (cq.Workplane("XY").box(x1 - x0, y1 - y0, z1 - z0, centered=False)
            .translate((x0, y0, z0)))


def cyl(d, start, axis, length):
    """Cylinder of diameter d from `start` along +axis ('x', 'y' or 'z')."""
    direction = {"x": (1, 0, 0), "y": (0, 1, 0), "z": (0, 0, 1)}[axis]
    return cq.Workplane(obj=cq.Solid.makeCylinder(d / 2, length, cq.Vector(*start),
                                                  cq.Vector(*direction)))


def rrect_xz(cx, cz, w, h, r, y_front, t):
    """Rounded rectangle in the XZ plane, from y_front backwards by t."""
    return (cq.Workplane("XZ", origin=(0, y_front, 0)).center(cx, cz)
            .sketch().rect(w, h).vertices().fillet(r).finalize().extrude(t))


def rounded_box(x, y, z, r):
    b = box(x, y, z)
    return b.edges().fillet(r) if r else b


DOWN = math.radians(DOWN_DEG)
N_DOWN = (math.cos(DOWN), -math.sin(DOWN))        # (Y, Z) outward normal of the chamfer
T_UP = (math.sin(DOWN), math.cos(DOWN))           # (Y, Z) along the chamfer, upwards


def housing_profile(x_range, inset=0.0):
    """Side housing outline (seen from the side) extruded over x_range.

    inset shrinks it evenly, which gives the inside of the shell."""
    y0, y1 = H_Y[0] + inset, H_Y[1] - inset
    z0, z1 = H_Z[0] + inset, H_Z[1] - inset
    solid = box(x_range, (y0, y1), (z0, z1))
    # Bottom-front chamfer: the line through the chamfer corner points, moved
    # inwards by `inset` along its normal.
    a = (H_Y[1] - CH_DEPTH, H_Z[0])
    a = (a[0] - inset * N_DOWN[0], a[1] - inset * N_DOWN[1])
    far = 40.0
    p1 = (a[0] - far * T_UP[0], a[1] - far * T_UP[1])
    p2 = (a[0] + far * T_UP[0], a[1] + far * T_UP[1])
    q2 = (p2[0] + far * N_DOWN[0], p2[1] + far * N_DOWN[1])
    q1 = (p1[0] + far * N_DOWN[0], p1[1] + far * N_DOWN[1])
    wedge = (cq.Workplane("YZ", origin=(x_range[0] - 1, 0, 0))
             .polyline([p1, p2, q2, q1]).close().extrude(x_range[1] - x_range[0] + 2))
    solid = solid.cut(wedge)
    r = max(H_R - inset, 0.6)
    return solid.edges("|X").fillet(r)


def chamfer_point(along, depth):
    """Point (Y, Z) on the chamfer's mid-line: `along` up the face from its
    middle, `depth` inwards from the outer surface."""
    a = (H_Y[1] - CH_DEPTH, H_Z[0])
    length = CH_DEPTH / T_UP[0]
    mid = (a[0] + T_UP[0] * length / 2, a[1] + T_UP[1] * length / 2)
    return (mid[0] + T_UP[0] * along - N_DOWN[0] * depth,
            mid[1] + T_UP[1] * along - N_DOWN[1] * depth)


def on_chamfer(solid_facing_y, along, depth):
    """Turn a solid built facing +Y around the origin so it faces down the
    chamfer, and move it to the chamfer."""
    y, z = chamfer_point(along, depth)
    return solid_facing_y.rotate((0, 0, 0), (1, 0, 0), -DOWN_DEG).translate((0, y, z))


def temple_bar():
    zc = sum(TEMPLE_Z) / 2
    half = (TEMPLE_Z[1] - TEMPLE_Z[0]) / 2
    centre = (TEMPLE_STRAIGHT_TO, zc - TEMPLE_BEND_R)
    phi = math.radians(TEMPLE_BEND_DEG)

    def arc_pt(radius, angle):
        return (centre[0] - radius * math.sin(angle), centre[1] + radius * math.cos(angle))

    tangent = (-math.cos(phi), -math.sin(phi))
    up_r, lo_r = TEMPLE_BEND_R + half, TEMPLE_BEND_R - half
    up_end = arc_pt(up_r, phi)
    lo_end = arc_pt(lo_r, phi)
    up_tail = (up_end[0] + tangent[0] * TEMPLE_TAIL, up_end[1] + tangent[1] * TEMPLE_TAIL)
    lo_tail = (lo_end[0] + tangent[0] * TEMPLE_TAIL, lo_end[1] + tangent[1] * TEMPLE_TAIL)
    tip_c = ((up_tail[0] + lo_tail[0]) / 2, (up_tail[1] + lo_tail[1]) / 2)
    tip = (tip_c[0] + tangent[0] * half, tip_c[1] + tangent[1] * half)
    start_y = H_Y[0] + 1.0
    sketch = (cq.Workplane("YZ", origin=(END_X, 0, 0))
              .moveTo(start_y, TEMPLE_Z[1])
              .lineTo(TEMPLE_STRAIGHT_TO, TEMPLE_Z[1])
              .threePointArc(arc_pt(up_r, phi / 2), up_end)
              .lineTo(*up_tail)
              .threePointArc(tip, lo_tail)
              .lineTo(*lo_end)
              .threePointArc(arc_pt(lo_r, phi / 2), (TEMPLE_STRAIGHT_TO, TEMPLE_Z[0]))
              .lineTo(start_y, TEMPLE_Z[0])
              .close())
    return sketch.extrude(TEMPLE_T).edges("not |X").fillet(1.2)


# ---------------------------------------------------------------- printed parts

def frame_front():
    f = rrect_xz(-LCX, 0, LENS_W + 2 * RIM, LENS_H + 2 * RIM, LENS_R + RIM, FRONT_Y, FRONT_T)
    f = f.union(rrect_xz(LCX, 0, LENS_W + 2 * RIM, LENS_H + 2 * RIM, LENS_R + RIM, FRONT_Y, FRONT_T))
    f = f.union(rrect_xz(0, sum(BROW_Z) / 2, 2 * FRAME_X, BROW_Z[1] - BROW_Z[0], 4, FRONT_Y, FRONT_T))
    f = f.union(box((-9, 9), (FRONT_Y - FRONT_T, FRONT_Y), (2, 16)))
    for s in (-1, 1):
        f = f.union(box(sorted((s * TAB[0][0], s * TAB[0][1])), TAB[1], TAB[2]))
    try:
        f = f.faces(">Y").edges().fillet(1.0)
    except Exception:
        pass
    for s in (-1, 1):
        f = f.cut(rrect_xz(s * LCX, 0, LENS_W, LENS_H, LENS_R, FRONT_Y + 1, FRONT_T + 2))
        f = f.cut(rrect_xz(s * LCX, 0, LENS_W + 2, LENS_H + 2, LENS_R + 1, FRONT_Y - FRONT_T + 2, 3))
        # pilot holes for the two M2 screws that hold each temple
        for y, z in tab_screws(s):
            f = f.cut(cyl(1.7, (END_X - 7 if s > 0 else -END_X, y, z), "x", 7))
    f = f.cut(box(*GROOVE))
    return f


def tab_screws(side):
    """(Y, Z) of the screws through a housing's inner wall into the end piece."""
    return [(-7.5, 10.0), (-7.5, 18.0)] if side > 0 else [(-1.0, 10.0), (-1.0, 18.0)]


def housing(side):
    """Shell + temple of one side, built on the right; mirror the result for the left."""
    shell = housing_profile(H_X).faces(">X").shell(-WALL)
    for y, z in POSTS:
        post = cyl(POST_D, (H_X[1] - POST_LEN, y, z), "x", POST_LEN)
        shell = shell.union(post).cut(cyl(1.7, (H_X[1] - POST_LEN, y, z), "x", POST_LEN + 0.1))
    shell = shell.union(temple_bar())
    # wires from the groove in the brow
    shell = shell.cut(box((H_X[0] - 1, H_X[0] + WALL + 1), (-3.2, -0.3), GROOVE[2]))
    for y, z in tab_screws(side):
        shell = shell.cut(cyl(2.3, (H_X[0] - 0.5, y, z), "x", WALL + 1))
    return shell


def right_housing():
    s = housing(+1)
    cam = XIAO_CAMERA
    s = s.cut(cyl(9.0, (cam[0], H_Y[1] - WALL - 1, cam[1]), "y", WALL + 2))          # camera
    s = s.cut(box((CX - 6, CX + 6), (-10.1, -3.1), (H_Z[0] - 3, XIAO_Z0 - 1.1)))       # USB-C
    s = s.cut(cyl(4.4, (CX, BUTTON_Y, H_Z[1] - WALL - 1), "z", WALL + 2))             # button
    for dy, dz in [(0, 0)] + [(4.2 * math.cos(math.radians(a)), 4.2 * math.sin(math.radians(a)))
                              for a in range(0, 360, 60)]:
        s = s.cut(cyl(1.8, (H_X[0] - 1, SPEAKER_C[0] + dy, SPEAKER_C[1] + dz), "x", WALL + 2))
    return s


def left_housing():
    """Built on the right side; the caller mirrors it."""
    s = housing(-1)
    s = s.cut(box((CX - 5, CX + 5), (H_Y[1] - WALL - 1, H_Y[1] + 1), (TOF_FRONT_Z - 3, TOF_FRONT_Z + 3)))
    window = box((CX - 5, CX + 5), (-WALL - 1, 1.0), (-3, 3))     # facing +Y around the origin
    s = s.cut(on_chamfer(window, 0, 0))
    s = s.cut(box((CX - 1.4, CX + 1.4), (SWITCH_Y - 3, SWITCH_Y + 3), (H_Z[1] - WALL - 1, H_Z[1] + 1)))
    return s


def lid():
    l = housing_profile((H_X[1], H_X[1] + LID_T))
    try:
        l = l.faces(">X").edges().fillet(0.8)
    except Exception:
        pass
    for y, z in POSTS:
        l = l.cut(cyl(2.3, (H_X[1] - 1, y, z), "x", LID_T + 2))
    return l


def lens(side):
    return rrect_xz(side * LCX, 0, LENS_W + 1.6, LENS_H + 1.6, LENS_R + 0.8, FRONT_Y - FRONT_T + 1.9, 1.9)


def nose_pad(side):
    pad = rounded_box((-2.5, 2.5), (-1.5, 1.5), (-5.5, 5.5), 1.4)
    return pad.rotate((0, 0, 0), (0, 0, 1), side * 35).translate((side * 5.0, FRONT_Y - FRONT_T - 2.8, -5.0))


# ---------------------------------------------------------------- electronics

XIAO_CAMERA = (CX, XIAO_Z0 + XIAO_H / 2)     # (X, Z) of the camera lens
BUTTON_Y = -1.0
SPEAKER_C = (-40.0, 11.0)                    # (Y, Z)
TOF_FRONT_Z = 14.0
SWITCH_Y = -1.5


def xiao():
    """XIAO ESP32S3 Sense facing forward: camera, expansion board, main board."""
    x = (CX - XIAO_W / 2, CX + XIAO_W / 2)
    z = (XIAO_Z0, XIAO_Z0 + XIAO_H)
    cx, cz = XIAO_CAMERA
    return {
        "xiao_main": (box(x, (-5.0, -3.8), z), "#1F2937"),
        "xiao_shield": (box((cx - 6.1, cx + 6.1), (-6.4, -5.0), (cz - 4, cz + 7)), "#C7CCD4"),
        "xiao_usbc": (rounded_box((cx - 4.5, cx + 4.5), (-8.2, -5.0), (XIAO_Z0 - 1.0, XIAO_Z0 + 6.3), 0.8), "#B5BAC2"),
        "xiao_b2b": (box((cx - 3.5, cx + 3.5), (-3.8, -1.0), (cz + 3, cz + 7)), "#2B2B2B"),
        "xiao_sense": (box(x, (-1.0, 0.2), z), "#1F2937"),
        "camera": (box((cx - 4.25, cx + 4.25), (0.2, 3.7), (cz - 4.25, cz + 4.25)), "#15171A"),
        "camera_lens": (cyl(6.0, (cx, 3.7, cz), "y", 2.2), "#2A2D33"),
        "camera_glass": (cyl(3.2, (cx, 5.9, cz), "y", 0.15), "#3D6FB6"),
    }


def tof(prefix):
    """VL53L1X breakout facing +Y, centred on the origin (sensor chip in front)."""
    return {
        f"{prefix}_pcb": (box((-TOF_W / 2, TOF_W / 2), (-1.0, 0.0), (-TOF_H / 2, TOF_H / 2)), "#6B3FA0"),
        f"{prefix}_chip": (box((-2.45, 2.45), (0.0, 1.56), (-1.25, 1.25)), "#111111"),
    }


def right_electronics():
    parts = xiao()
    parts["button"] = (box((CX - 3, CX + 3), (BUTTON_Y - 3, BUTTON_Y + 3), (IN_Z[1] - 3.5, IN_Z[1])), "#2B2B2B")
    parts["button_cap"] = (cyl(3.8, (CX, BUTTON_Y, IN_Z[1]), "z", WALL + 1.5), "#F5A524")
    parts["motor"] = (cyl(MOTOR_D, (H_X[0] + WALL, -16.0, 11.0), "x", MOTOR_T), "#D3D7DD")
    parts["amp_pcb"] = (box((CX - AMP_W / 2, CX + AMP_W / 2), (-26.0, -24.4), (11 - AMP_H / 2, 11 + AMP_H / 2)), "#2F5DB8")
    parts["amp_chip"] = (box((CX - 1.5, CX + 1.5), (-24.4, -23.5), (9.5, 12.5)), "#111111")
    parts["speaker"] = (cyl(SPEAKER_D, (H_X[0] + WALL, SPEAKER_C[0], SPEAKER_C[1]), "x", SPEAKER_T), "#1B1C1F")
    return parts


def left_electronics():
    """Built on the right side; the caller mirrors it."""
    parts = {}
    for name, (solid, colour) in tof("tof_front").items():
        y = IN_Y[1] - 1.56            # chip touches the inside of the front wall
        parts[name] = (solid.translate((CX, y, TOF_FRONT_Z)), colour)
    for name, (solid, colour) in tof("tof_down").items():
        parts[name] = (on_chamfer(solid, 0, WALL + 1.56).translate((CX, 0, 0)), colour)
    parts["switch"] = (box((CX - 1.8, CX + 1.8), (SWITCH_Y - 4.3, SWITCH_Y + 4.3), (IN_Z[1] - 3.6, IN_Z[1] - 0.1)), "#2B2B2B")
    parts["switch_knob"] = (box((CX - 0.75, CX + 0.75), (SWITCH_Y - 1.0, SWITCH_Y + 1.0), (IN_Z[1], IN_Z[1] + WALL + 1.2)), "#E8E8E8")
    bx, by, bz = BATTERY
    parts["battery"] = (rounded_box((H_X[0] + WALL, H_X[0] + WALL + bx), (-8.5 - by, -8.5), (-3.0, -3.0 + bz), 1.5), "#B9BFC8")
    return parts


# ---------------------------------------------------------------- build

def mirror(wp):
    return wp.mirror("YZ")


def build():
    printed = {
        "frame_front": frame_front(),
        "temple_right": right_housing(),
        "lid_right": lid(),
        "temple_left": mirror(left_housing()),
        "lid_left": mirror(lid()),
    }
    clear = {"lens_right": lens(1), "lens_left": lens(-1)}
    pads = {"nose_pad_right": nose_pad(1), "nose_pad_left": nose_pad(-1)}
    elec = {name: v for name, v in right_electronics().items()}
    elec.update({name: (mirror(s), c) for name, (s, c) in left_electronics().items()})
    return printed, clear, pads, elec


def collisions(named):
    """Pairs of solids whose overlap is more than a speck."""
    items = list(named.items())
    hits = []
    for i, (na, a) in enumerate(items):
        ba = a.val().BoundingBox()
        for nb, b in items[i + 1:]:
            bb = b.val().BoundingBox()
            if (ba.xmin > bb.xmax or bb.xmin > ba.xmax or ba.ymin > bb.ymax or bb.ymin > ba.ymax
                    or ba.zmin > bb.zmax or bb.zmin > ba.zmax):
                continue
            common = a.val().intersect(b.val())
            vol = common.Volume() if common is not None else 0.0
            if vol > 0.01:
                hits.append((na, nb, round(vol, 2)))
    return hits


def mesh(wp, tol=0.04):
    verts, tris = wp.val().tessellate(tol, 0.15)
    pos = np.array([(v.x, v.y, v.z) for v in verts], dtype=np.float32)
    idx = np.array(tris, dtype=np.uint32).reshape(-1)
    return (base64.b64encode(pos.tobytes()).decode(), base64.b64encode(idx.tobytes()).decode(), len(idx) // 3)


LABELS = {  # number shown on the drawings -> the part it points at
    1: "camera", 2: "tof_front_pcb", 3: "tof_down_pcb", 4: "speaker", 5: "motor",
    6: "battery", 7: "button_cap", 8: "switch_knob", 9: "frame_front",
}


def main():
    (OUT / "stl").mkdir(parents=True, exist_ok=True)
    printed, clear, pads, elec = build()

    solids = dict(printed)
    solids.update({k: v for k, v in clear.items()})
    solids.update({k: v for k, v in pads.items()})
    solids.update({k: s for k, (s, _) in elec.items()})
    hits = collisions(solids)
    print("collisions:", hits or "none")

    for name, wp in printed.items():
        cq.exporters.export(wp, str(OUT / "stl" / f"{name}.stl"), tolerance=0.02, angularTolerance=0.1)

    assy = cq.Assembly(name="baseera_glasses")
    frame_colour = "#232838"
    for name, wp in printed.items():
        assy.add(wp, name=name, color=cq.Color(frame_colour))
    for name, wp in clear.items():
        assy.add(wp, name=name, color=cq.Color(0.23, 0.25, 0.31, 0.5))
    for name, wp in pads.items():
        assy.add(wp, name=name, color=cq.Color(0.85, 0.87, 0.9, 0.8))
    for name, (wp, colour) in elec.items():
        assy.add(wp, name=name, color=cq.Color(colour))
    assy.export(str(OUT / "baseera_glasses.step"))

    parts = []
    for name, wp in printed.items():
        parts.append(("print", name, frame_colour, wp))
    for name, wp in clear.items():
        parts.append(("lens", name, "#3A4150", wp))
    for name, wp in pads.items():
        parts.append(("pad", name, "#D8DEE6", wp))
    for name, (wp, colour) in elec.items():
        parts.append(("elec", name, colour, wp))

    model = {"parts": [], "labels": {}}
    for group, name, colour, wp in parts:
        pos, idx, n = mesh(wp)
        model["parts"].append({"name": name, "group": group, "color": colour, "pos": pos, "idx": idx})
        print(f"{name:18s} {n:6d} triangles")
    for number, name in LABELS.items():
        c = solids[name].val().BoundingBox().center
        at = (c.x, c.y, c.z) if name != "frame_front" else (LCX + 18, FRONT_Y, -LENS_H / 2 - RIM / 2)
        model["labels"][number] = {"part": name, "at": [round(v, 2) for v in at]}
    (OUT / "model.json").write_text(json.dumps(model), encoding="utf-8")

    for name, wp in printed.items():
        bb = wp.val().BoundingBox()
        print(f"{name:14s} {bb.xlen:6.1f} x {bb.ylen:6.1f} x {bb.zlen:6.1f} mm, "
              f"{wp.val().Volume() / 1000:5.1f} cm3")
    if hits:
        raise SystemExit(1)


if __name__ == "__main__":
    try:
        main()
    finally:
        # OpenCascade can crash while Python shuts down on Windows; skip that.
        import sys
        sys.stdout.flush()
        os._exit(0 if sys.exc_info()[0] is None else 1)
