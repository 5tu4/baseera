"""Baseera glasses v2: printable parts for the components actually bought.

Builds the printable PETG parts and simple models of the electronics, checks
that no two parts collide, and writes:

  out/stl/*.stl              parts in the assembly position (for CAD)
  out/print/*.stl            the same parts laid flat for the printer
  out/baseera_glasses.step   the whole assembly, electronics included
  out/model.json             meshes for the 3D viewer (make_viewer.py)

Layout (v2):
  Right housing: XIAO ESP32S3 Sense (camera looks ahead, USB-C points up
    through its own opening in the top wall), push button on top, 35x25x6.5 mm
    cavity speaker against the inner wall (grille towards the head), MAX98357A
    taped to the back of the speaker, vibration motor and Wi-Fi antenna stuck
    to the inside of the lid.
  Left housing: front VL53L1X, floor VL53L1X on the 60-degree chamfer, slide
    switch on top, TP4056 USB-C charger standing in a cradle with its port
    pointing up through its own opening in the top wall, 602030 300 mAh battery
    behind it. Both ports face up so a cable reaches them while the glasses
    rest on a table.
  Frame front (v3): rectangular 40 mm lenses, Wayfarer-style nose gap (12 mm
  under the bridge, 36 mm at the bottom), 2 mm acrylic lenses in a rebate from
  the back. Wires cross in a groove at the back of the top rim. Temples are
  screwed to the frame's end pieces (no hinge) and splay out 5 degrees.

Every rib inside the housings grows from the inner wall, so the housings print
open side up with no supports.

Numbers marked CHECK are the ones worth measuring on the real parts.

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
# Rectangular lenses with a Wayfarer-style nose gap (v3, 2026-11-02): the gap is
# 12 mm wide under the bridge and opens to 36 mm at the bottom edge; the lens
# openings are 40 mm tall and their nose-side edge follows the gap.
FRONT_Y, FRONT_T = 3.0, 6.0              # front face at Y=3, back face at Y=-3
FRAME_Z = (-24.5, 28.0)                  # bottom and top edges (top flush with the housings)
LENS_Z = (-20.0, 20.0)                   # lens opening, 40 tall, centred on the eye
LENS_X_OUT = 62.0                        # outer edge of the lens opening: 6 mm rim to the housing
END_X = 68.0                             # outer face of the frame = inner face of the housings
GAP_TOP_W, GAP_TOP_Z = 12.0, 8.0         # nose gap under the bridge: width, height of the bridge's underside
GAP_BOT_W = 36.0                         # nose gap at the bottom edge of the frame
RIM_NOSE = 4.8                           # rim between the gap and the lens, measured horizontally
LENS_R, CORNER_R, GAP_R = 4.0, 5.0, 2.5  # roundings: lens corners, frame corners, gap corners
LENS_GAP, LENS_T = 0.8, 1.9              # rebate clearance around the lens; acrylic thickness
TAB = ((LENS_X_OUT, END_X), (-10.0, FRONT_Y), (8.0, 22.0))   # end piece the temple screws to
GROOVE = ((-70.0, 70.0), (-3.8, -0.4), (21.5, 25.5))   # wire groove, back of the top rim, open at both ends
SPLAY_DEG = 5.0                          # temples open 5 degrees past square
PIVOT = (END_X, FRONT_Y)                 # (X, Y) the splay turns about
GAP_K = (GAP_BOT_W - GAP_TOP_W) / 2 / (GAP_TOP_Z - FRAME_Z[0])   # slope of the gap's edge, X per mm down

# --- side housings (built on the right, mirrored for the left) -----------------
WALL = 1.6
H_X = (END_X, 88.0)                      # open on the outer side; the lid closes it
H_Y = (-54.0, 7.0)
H_Z = (-6.0, 28.0)
H_R = 4.0                                # edge rounding seen from the side
CH_DEPTH = 14.0                          # bottom-front chamfer, depth along Y
DOWN_DEG = 60.0                          # chamfer faces this far below horizontal
LID_T = 1.6
POST_D, POST_LEN = 4.0, 4.5              # lid screw posts (M2 x 6 self-tapping)
CX = (H_X[0] + WALL + H_X[1]) / 2        # middle of the housing's inside, X
IN_X0 = H_X[0] + WALL
IN_Y = (H_Y[0] + WALL, H_Y[1] - WALL)
IN_Z = (H_Z[0] + WALL, H_Z[1] - WALL)
_P = POST_D / 2 - 0.5                    # posts sit into the corner walls
POSTS = [(IN_Y[0] + _P, IN_Z[1] - _P),   # (Y, Z): back top
         (IN_Y[0] + _P, IN_Z[0] + _P),   # back bottom
         (IN_Y[1] - _P, IN_Z[1] - _P)]   # front top
FIN = 1.2                                # ribs inside the housings
FIN_X = (IN_X0 - 0.2, H_X[1] - 0.3)      # ribs fuse into the inner wall, stop short of the lid
FIN_Z0 = IN_Z[0] - 0.2                   # and into the floor

# --- temples --------------------------------------------------------------------
TEMPLE_T = 4.5
TEMPLE_Z = (10.0, 17.0)
TEMPLE_STRAIGHT_TO = -105.0
TEMPLE_BEND_R, TEMPLE_BEND_DEG, TEMPLE_TAIL = 45.0, 40.0, 10.0

# --- electronics ------------------------------------------------------------------
XIAO_W, XIAO_H = 17.8, 21.0              # board, X by Z (it stands upright, USB-C down)
XIAO_Z1 = 22.5                           # top edge of the board (USB-C up), just under the lid post
XIAO_Z0 = XIAO_Z1 - XIAO_H               # bottom edge, clear of the front chamfer
CAM_FROM_USB_END = 10.5                  # CHECK: lens centre measured from the USB-C end of the board
USB_PLUG = (12.5, 6.6)                   # opening in the top wall for a USB-C plug's overmould, X by Y
TOF_W, TOF_H = 18.0, 13.0                # VL53L1X breakout
AMP_W, AMP_H = 17.8, 19.3                # MAX98357A breakout
SPEAKER = (6.5, 35.0, 25.0)              # 3525 cavity speaker (AliExpress 1005007390381560): X, Y, Z
SPEAKER_TAB = 1.3                        # locating tab on one short end
MOTOR_D, MOTOR_T = 10.0, 2.7
BATTERY = (6.0, 30.0, 20.0)              # CHECK: 602030 LiPo 300 mAh: X, Y, Z
BATTERY_TAB = (5.2, 2.6, 10.0)           # protection board sticking out of one end
CHARGER = (17.5, 26.0)                   # CHECK: TP4056 USB-C board, X by Z (stands upright, port up)
CHARGER_PCB_T, CHARGER_PARTS_T = 1.0, 3.2


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


def prism_xz(pts, r, y_front, t):
    """Polygon in the XZ plane, corners rounded by r, from y_front backwards by t."""
    w = cq.Workplane("XZ", origin=(0, y_front, 0)).polyline(pts).close().extrude(t)
    return w.edges("|Y").fillet(r) if r else w


def fillet_at(solid, xz_points, r):
    """Round the edges running along Y through the given (X, Z) points."""
    for x, z in xz_points:
        solid = solid.edges(cq.selectors.BoxSelector((x - 1, -30, z - 1), (x + 1, 30, z + 1))).fillet(r)
    return solid


def offset_polygon(pts, d):
    """Grow a convex polygon by d: every edge moves outwards, corners stay sharp."""
    n = len(pts)
    cx = sum(p[0] for p in pts) / n
    cz = sum(p[1] for p in pts) / n
    lines = []
    for i in range(n):
        (x0, z0), (x1, z1) = pts[i], pts[(i + 1) % n]
        ex, ez = x1 - x0, z1 - z0
        length = math.hypot(ex, ez)
        nx, nz = ez / length, -ex / length
        if nx * ((x0 + x1) / 2 - cx) + nz * ((z0 + z1) / 2 - cz) < 0:
            nx, nz = -nx, -nz
        lines.append(((x0 + nx * d, z0 + nz * d), (ex, ez)))
    out = []
    for i in range(n):
        (px, pz), (ex, ez) = lines[i - 1]
        (qx, qz), (fx, fz) = lines[i]
        det = -ex * fz + fx * ez
        t = ((qx - px) * (-fz) + fx * (qz - pz)) / det
        out.append((px + t * ex, pz + t * ez))
    return out


def gap_x(z):
    """Half-width of the nose gap at height z (for z below the bridge)."""
    return GAP_TOP_W / 2 + (GAP_TOP_Z - z) * GAP_K


def lens_outline(side, grow=0.0):
    """(X, Z) corners of a lens opening: vertical nose edge above the bridge's
    underside, then parallel to the gap's edge down to the bottom."""
    x_in = GAP_TOP_W / 2 + RIM_NOSE
    pts = [(x_in, LENS_Z[1]), (LENS_X_OUT, LENS_Z[1]), (LENS_X_OUT, LENS_Z[0]),
           (gap_x(LENS_Z[0]) + RIM_NOSE, LENS_Z[0]), (x_in, GAP_TOP_Z)]
    if grow:
        pts = offset_polygon(pts, grow)
    return [(side * x, z) for x, z in pts]


def place(wp):
    """Splay a right-side part (housing, lid or electronics) about the end piece."""
    return wp.rotate((PIVOT[0], PIVOT[1], 0), (PIVOT[0], PIVOT[1], 1), SPLAY_DEG)


def mirror(wp):
    return wp.mirror("YZ")


def place_side(side, wp):
    """Splay a right-side solid; mirror it too for the left."""
    return place(wp) if side > 0 else mirror(place(wp))


DOWN = math.radians(DOWN_DEG)
N_DOWN = (math.cos(DOWN), -math.sin(DOWN))        # (Y, Z) outward normal of the chamfer
T_UP = (math.sin(DOWN), math.cos(DOWN))           # (Y, Z) along the chamfer, upwards


def housing_profile(x_range, inset=0.0):
    """Side housing outline (seen from the side) extruded over x_range.

    inset shrinks it evenly, which gives the inside of the shell."""
    y0, y1 = H_Y[0] + inset, H_Y[1] - inset
    z0, z1 = H_Z[0] + inset, H_Z[1] - inset
    solid = box(x_range, (y0, y1), (z0, z1))
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


def fin_y(y, z_top, x=FIN_X):
    """Rib standing on the inner wall and the floor, thin in Y (prints without support)."""
    return box(x, (y, y + FIN), (FIN_Z0, z_top))


# ---------------------------------------------------------------- positions

# right housing (local, before the splay)
XIAO_CAMERA = (CX, XIAO_Z1 - CAM_FROM_USB_END)     # (X, Z) of the camera lens
XIAO_USB_Y = (-8.2, -5.0)                           # the USB-C, behind the main board
XIAO_FIN_Y = -7.9                                   # rib behind the XIAO's RF shield
BUTTON_Y = -20.0                                    # above the speaker, behind the USB-C opening
SPEAKER_Y = (-50.8, -15.8)                          # 35 mm; tab towards the back wall
SPEAKER_Z = (IN_Z[0] + 0.5, IN_Z[0] + 0.5 + SPEAKER[2])
SPEAKER_C = (sum(SPEAKER_Y) / 2, sum(SPEAKER_Z) / 2)  # (Y, Z)
SPEAKER_FIN_Y = -14.3                               # rib in front of the speaker
AMP_Y = (-45.0, -25.7)
AMP_Z = (SPEAKER_C[1] - AMP_W / 2, SPEAKER_C[1] + AMP_W / 2)
MOTOR_YZ = (-30.0, SPEAKER_C[1])

# left housing (local, before the splay and the mirror)
TOF_FRONT_Z = 14.0
SWITCH_Y = -1.5
CHG_GAP = (-15.4, -10.4)                            # the charger stands between two ribs
CHG_Z0 = IN_Z[0] + 0.3                              # bottom edge of its board, on the floor
CHG_PCB_Y = (CHG_GAP[1] - CHARGER_PCB_T, CHG_GAP[1])            # board against the front rib
CHG_PARTS_Y = (CHG_PCB_Y[0] - CHARGER_PARTS_T, CHG_PCB_Y[0])    # parts and port face backwards
CHG_PORT_Y = sum(CHG_PARTS_Y) / 2
CHG_Z1 = CHG_Z0 + CHARGER[1]                        # top edge; the port sticks 1 mm above it
CHG_LEDGE_Z = CHG_Z1 + 0.3                          # ledge over its inner top corner
BATTERY_Y = (CHG_GAP[0] - FIN - 3.0 - BATTERY[1], CHG_GAP[0] - FIN - 3.0)
BATTERY_Z = (IN_Z[0] + 2.4, IN_Z[0] + 2.4 + BATTERY[2])


# ---------------------------------------------------------------- printed parts

def tab_screws(side):
    """(Y, Z) of the screws through a housing's inner wall into the end piece."""
    return [(-7.5, 10.0), (-7.5, 18.0)] if side > 0 else [(-1.0, 10.0), (-1.0, 18.0)]


def end_piece(side):
    """End piece with its pilot holes, built on the right and splayed; mirrored for the left."""
    tab = box(TAB[0], TAB[1], TAB[2])
    for y, z in tab_screws(side):
        tab = tab.cut(cyl(1.7, (END_X - 5.4, y, z), "x", 6.0))
    return place_side(side, tab)


def frame_front():
    zb, zt = FRAME_Z
    xo = END_X + 1.0                         # trimmed back to the housings' splayed planes below
    outline = [(-xo, zt), (xo, zt), (xo, zb), (gap_x(zb), zb), (GAP_TOP_W / 2, GAP_TOP_Z),
               (-GAP_TOP_W / 2, GAP_TOP_Z), (-gap_x(zb), zb), (-xo, zb)]
    f = prism_xz(outline, 0, FRONT_Y, FRONT_T)
    for sgn in (-1, 1):
        f = f.cut(place_side(sgn, box((END_X, 90), (-30, 20), (-40, 40))))
    f = fillet_at(f, [(sgn * END_X, z) for sgn in (-1, 1) for z in (zb, zt)], CORNER_R)
    f = fillet_at(f, [(sgn * GAP_TOP_W / 2, GAP_TOP_Z) for sgn in (-1, 1)]
                  + [(sgn * gap_x(zb), zb) for sgn in (-1, 1)], GAP_R)
    for sgn in (-1, 1):
        f = f.cut(prism_xz(lens_outline(sgn), LENS_R, FRONT_Y + 1, FRONT_T + 2))
    try:
        f = f.faces(">Y").edges().fillet(1.0)
    except Exception:
        pass
    for sgn in (-1, 1):
        f = f.union(end_piece(sgn))
    for sgn in (-1, 1):   # rebate for the lens, 2 mm deep from the back (cuts into the end pieces too)
        f = f.cut(prism_xz(lens_outline(sgn, LENS_GAP), LENS_R + LENS_GAP, FRONT_Y - FRONT_T + 2.0, 3.0))
    f = f.cut(box(*GROOVE))
    return f


def housing(side):
    """Shell + temple of one side, built on the right; mirror the result for the left."""
    shell = housing_profile(H_X).faces(">X").shell(-WALL)
    for y, z in POSTS:
        post = cyl(POST_D, (H_X[1] - POST_LEN, y, z), "x", POST_LEN)
        shell = shell.union(post).cut(cyl(1.7, (H_X[1] - POST_LEN, y, z), "x", POST_LEN + 0.1))
    shell = shell.union(temple_bar())
    # wires from the groove in the brow
    shell = shell.cut(box((H_X[0] - 1, H_X[0] + WALL + 1), (GROOVE[1][0] + 0.6, GROOVE[1][1] + 0.1), GROOVE[2]))
    for y, z in tab_screws(side):
        shell = shell.cut(cyl(2.3, (H_X[0] - 0.5, y, z), "x", WALL + 1))
    return shell


def top_port(y_centre, z_bottom):
    """Opening in the top wall for a USB-C plug, down to the receptacle's face."""
    return box((CX - USB_PLUG[0] / 2, CX + USB_PLUG[0] / 2),
               (y_centre - USB_PLUG[1] / 2, y_centre + USB_PLUG[1] / 2),
               (z_bottom, H_Z[1] + 1))


def grille():
    """Staggered 1.6 mm holes through the inner wall over the speaker's diaphragm."""
    cy, cz = SPEAKER_C
    a, b = SPEAKER[1] / 2 - 4.5, SPEAKER[2] / 2 - 4.5     # ellipse inside the speaker's frame
    pitch = 2.6
    pts = []
    for j in range(-6, 7):
        z = cz + j * pitch * 0.866
        for i in range(-8, 9):
            y = cy + (i + 0.5 * (j % 2)) * pitch
            if ((y - cy) / a) ** 2 + ((z - cz) / b) ** 2 <= 1.0:
                pts.append((y, z))
    return (cq.Workplane("YZ", origin=(H_X[0] - 1, 0, 0)).pushPoints(pts)
            .circle(0.8).extrude(WALL + 2))


def right_housing():
    s = housing(+1)
    s = s.union(fin_y(XIAO_FIN_Y, 7.8))                                   # XIAO can't slide back (stays under the screw head)
    s = s.union(fin_y(SPEAKER_FIN_Y, 21.5, (FIN_X[0], IN_X0 + SPEAKER[0] + 1.4))
                .cut(box((H_X[0], IN_X0 + SPEAKER[0] + 2), (SPEAKER_FIN_Y - 1, SPEAKER_FIN_Y + FIN + 1),
                         (H_Z[0], IN_Z[0] + 4.0))))                        # speaker wires pass under it
    cam = XIAO_CAMERA
    s = s.cut(cyl(10.0, (cam[0], H_Y[1] - WALL - 1, cam[1]), "y", WALL + 2))         # camera window
    s = s.cut(top_port(sum(XIAO_USB_Y) / 2, XIAO_Z1 + 0.9))                         # XIAO USB-C
    s = s.cut(cyl(4.4, (CX, BUTTON_Y, H_Z[1] - WALL - 1), "z", WALL + 2))            # button
    s = s.cut(grille())
    return s


def left_housing():
    """Built on the right side; the caller mirrors it."""
    s = housing(-1)
    s = s.union(fin_y(CHG_GAP[0] - FIN, 20.0)).union(fin_y(CHG_GAP[1], 20.0))        # charger cradle
    s = s.union(box((FIN_X[0], IN_X0 + 2.5), (CHG_GAP[0] - FIN, CHG_GAP[1] + FIN),
                    (CHG_LEDGE_Z, CHG_LEDGE_Z + FIN)))                               # keeps it down
    s = s.cut(box((CX - 5, CX + 5), (H_Y[1] - WALL - 1, H_Y[1] + 1), (TOF_FRONT_Z - 3, TOF_FRONT_Z + 3)))
    window = box((CX - 5, CX + 5), (-WALL - 1, 1.0), (-3, 3))     # facing +Y around the origin
    s = s.cut(on_chamfer(window, 0, 0))
    s = s.cut(box((CX - 1.4, CX + 1.4), (SWITCH_Y - 3, SWITCH_Y + 3), (H_Z[1] - WALL - 1, H_Z[1] + 1)))
    s = s.cut(top_port(CHG_PORT_Y, CHG_Z1 + 0.9))                                     # charger USB-C
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
    """Acrylic lens: 0.2 mm smaller than the rebate all round, sitting in it."""
    grow = LENS_GAP - 0.2
    return prism_xz(lens_outline(side, grow), LENS_R + grow, FRONT_Y - FRONT_T + LENS_T, LENS_T)


def lens_dxf(path):
    """Both lens outlines, flat, for the laser cutter (mm)."""
    grow = LENS_GAP - 0.2
    wp = cq.Workplane("XY")
    for side in (-1, 1):
        face = (cq.Workplane("XY").polyline(lens_outline(side, grow)).close().extrude(1.0)
                .edges("|Z").fillet(LENS_R + grow).faces("<Z").val())
        wp = wp.add(face)
    cq.exporters.export(wp, str(path))


# ---------------------------------------------------------------- electronics

def xiao():
    """XIAO ESP32S3 Sense standing upright, camera forward, USB-C up."""
    x = (CX - XIAO_W / 2, CX + XIAO_W / 2)
    z = (XIAO_Z0, XIAO_Z1)
    cx, cz = XIAO_CAMERA
    return {
        "xiao_main": (box(x, (-5.0, -3.8), z), "#1F2937"),
        "xiao_shield": (box((cx - 6.1, cx + 6.1), (-6.4, -5.0), (cz - 7, cz + 4)), "#C7CCD4"),
        "xiao_usbc": (rounded_box((cx - 4.5, cx + 4.5), XIAO_USB_Y, (XIAO_Z1 - 6.3, XIAO_Z1 + 1.0), 0.8), "#B5BAC2"),
        "xiao_b2b": (box((cx - 3.5, cx + 3.5), (-3.8, -1.0), (cz - 7, cz - 3)), "#2B2B2B"),
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
    sx = (IN_X0, IN_X0 + SPEAKER[0])
    parts["speaker"] = (rounded_box(sx, SPEAKER_Y, SPEAKER_Z, 1.5), "#1B1C1F")
    parts["speaker_tab"] = (box((CX - 1.5, CX + 1.5), (SPEAKER_Y[0] - SPEAKER_TAB, SPEAKER_Y[0]),
                                (SPEAKER_C[1] - 2.5, SPEAKER_C[1] + 2.5)), "#E6E6E6")
    ax = (sx[1] + 0.6, sx[1] + 2.2)                                  # taped to the speaker's back
    parts["amp_pcb"] = (box(ax, AMP_Y, AMP_Z), "#2F5DB8")
    parts["amp_chip"] = (box((ax[1], ax[1] + 1.0), (sum(AMP_Y) / 2 - 1.5, sum(AMP_Y) / 2 + 1.5),
                             (SPEAKER_C[1] - 1.5, SPEAKER_C[1] + 1.5)), "#111111")
    parts["motor"] = (cyl(MOTOR_D, (H_X[1] - MOTOR_T, MOTOR_YZ[0], MOTOR_YZ[1]), "x", MOTOR_T), "#D3D7DD")
    parts["antenna"] = (box((H_X[1] - 0.6, H_X[1]), (-24.0, -10.0), (12.0, 20.0)), "#C9A227")
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
    hx = (CX - CHARGER[0] / 2, CX + CHARGER[0] / 2)
    parts["charger_pcb"] = (box(hx, CHG_PCB_Y, (CHG_Z0, CHG_Z1)), "#2F5DB8")
    parts["charger_parts"] = (box((hx[0] + 2, hx[1] - 2), CHG_PARTS_Y, (CHG_Z0 + 2.0, CHG_Z1 - 7.0)), "#111111")
    parts["charger_usb"] = (rounded_box((CX - 4.5, CX + 4.5), CHG_PARTS_Y, (CHG_Z1 - 6.4, CHG_Z1 + 1.0), 0.8), "#B5BAC2")
    bx = (IN_X0, IN_X0 + BATTERY[0])
    parts["battery"] = (rounded_box(bx, BATTERY_Y, BATTERY_Z, 1.5), "#B9BFC8")
    tx, ty, tz = BATTERY_TAB
    bzc = sum(BATTERY_Z) / 2
    parts["battery_tab"] = (box((bx[0] + 0.4, bx[0] + 0.4 + tx), (BATTERY_Y[1], BATTERY_Y[1] + ty),
                                (bzc - tz / 2, bzc + tz / 2)), "#2F5DB8")
    return parts


# ---------------------------------------------------------------- build

def build():
    r_house, l_house, l_lid = right_housing(), left_housing(), lid()
    frame = frame_front()
    local = {   # un-splayed, for the printer
        "frame_front": frame,
        "temple_right": r_house,
        "lid_right": l_lid,
        "temple_left": mirror(l_house),
        "lid_left": mirror(l_lid),
    }
    printed = {   # in the assembly position
        "frame_front": frame,
        "temple_right": place(r_house),
        "lid_right": place(l_lid),
        "temple_left": mirror(place(l_house)),
        "lid_left": mirror(place(l_lid)),
    }
    clear = {"lens_right": lens(1), "lens_left": lens(-1)}
    pads = {}
    elec = {name: (place(s), c) for name, (s, c) in right_electronics().items()}
    elec.update({name: (mirror(place(s)), c) for name, (s, c) in left_electronics().items()})
    return local, printed, clear, pads, elec


PRINT_ROT = {   # how each part lies on the printer bed: (axis, degrees) about the origin
    "frame_front": ("x", -90),      # front face down
    "temple_right": ("y", -90),     # open side up, temple flat
    "lid_right": ("y", -90),        # outer face up
    "temple_left": ("y", 90),
    "lid_left": ("y", 90),
}


def for_printer(name, wp):
    axis, deg = PRINT_ROT[name]
    end = {"x": (1, 0, 0), "y": (0, 1, 0)}[axis]
    wp = wp.rotate((0, 0, 0), end, deg)
    bb = wp.val().BoundingBox()
    return wp.translate((-(bb.xmin + bb.xmax) / 2, -(bb.ymin + bb.ymax) / 2, -bb.zmin))


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
    10: "charger_pcb", 11: "xiao_usbc", 12: "charger_usb",
}


def main():
    (OUT / "stl").mkdir(parents=True, exist_ok=True)
    (OUT / "print").mkdir(parents=True, exist_ok=True)
    local, printed, clear, pads, elec = build()

    solids = dict(printed)
    solids.update({k: v for k, v in clear.items()})
    solids.update({k: v for k, v in pads.items()})
    solids.update({k: s for k, (s, _) in elec.items()})
    hits = collisions(solids)
    print("collisions:", hits or "none")

    for name, wp in printed.items():
        cq.exporters.export(wp, str(OUT / "stl" / f"{name}.stl"), tolerance=0.02, angularTolerance=0.1)
    for name, wp in local.items():
        flat = for_printer(name, wp)
        cq.exporters.export(flat, str(OUT / "print" / f"{name}.stl"), tolerance=0.02, angularTolerance=0.1)
        bb = flat.val().BoundingBox()
        print(f"print/{name:14s} footprint {bb.xlen:6.1f} x {bb.ylen:6.1f} mm, height {bb.zlen:5.1f} mm")

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
    lens_dxf(OUT / "lenses.dxf")

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
        at = (c.x, c.y, c.z) if name != "frame_front" else (40.0, FRONT_Y, (FRAME_Z[0] + LENS_Z[0]) / 2)
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
