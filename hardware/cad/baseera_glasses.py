"""Baseera glasses v4: printable parts for the components actually bought.

Builds the printable PETG parts, simple models of the electronics and of the
wire bundles between them, checks that nothing collides, and writes:

  out/stl/*.stl              parts in the assembly position (for CAD)
  out/print/*.stl            the same parts laid flat for the printer
  out/baseera_glasses.step   the whole assembly, electronics and wires included
  out/lenses.dxf             both lens outlines for the laser cutter
  out/model.json             meshes for the 3D viewer (make_viewer.py)

Layout (temples v4, 2026-11-03):
  Right housing: XIAO ESP32S3 Sense at the front. Its camera lens goes through
    the front wall; its USB-C points up through the top wall, right over the
    connector (the connector sits between the XIAO's two boards, under the
    camera). Behind it the MAX98357A stands on the inner wall, then the
    35 x 25 mm speaker lies against the inner wall with the grille towards the
    head. Push button in the top wall. Vibration module in a frame on the lid.
  Left housing: front VL53L1X behind the front wall, floor VL53L1X on the
    60-degree chamfer, slide switch on top, 5 x 26 x 37 mm LiPo standing on the
    inner wall, and the TP4056 USB-C charger lying upside down near the floor
    at the back, its port through the back wall.
  Wires: one bundle crosses in the groove at the back of the frame's top rim;
    inside each housing the bundles are modelled like parts and checked for room.
  Frame front (v3): rectangular 40 mm lenses, Wayfarer-style nose gap (12 mm
    under the bridge, 36 mm at the bottom), 2 mm acrylic lenses in a rebate from
    the back. Temples are screwed to the frame's end pieces (no hinge) and
    splay out 5 degrees.

Every rib grows from the inner wall or the floor, and the lids' ribs grow from
the lid, so the housings print open side up and the lids outer face down, with
no supports.

Numbers marked CHECK are worth measuring on the real parts.

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
H_X = (END_X, 91.0)                      # open on the outer side; the lid closes it
H_Y = (-72.0, 7.0)
H_Z = (-6.0, 28.0)
H_R = 4.0                                # edge rounding seen from the side
H_R_TOP_FRONT = 2.0                      # tighter at the top front, where the camera sits
CH_DEPTH = 14.0                          # bottom-front chamfer, depth along Y
DOWN_DEG = 60.0                          # chamfer faces this far below horizontal
LID_T = 1.6
POST_D, POST_LEN = 4.0, 4.5              # lid screw posts (M2 x 6 self-tapping)
CX = (H_X[0] + WALL + H_X[1]) / 2        # middle of the housing's inside, X
IN_X0 = H_X[0] + WALL
IN_Y = (H_Y[0] + WALL, H_Y[1] - WALL)
IN_Z = (H_Z[0] + WALL, H_Z[1] - WALL)
_P = POST_D / 2 - 0.5                    # corner posts sit into the walls
POSTS = {   # (Y, Z) of the lid screws on each side, clear of the parts inside
    1: [(IN_Y[0] + _P, IN_Z[1] - _P), (IN_Y[0] + _P, IN_Z[0] + _P),
        (-24.0, IN_Z[1] - _P), (-3.0, -0.6)],                    # last one: in the chamfer, under the XIAO
    -1: [(IN_Y[0] + _P, IN_Z[1] - _P), (IN_Y[0] + _P, IN_Z[0] + _P),
         (-24.0, IN_Z[1] - _P), (IN_Y[1] - _P, IN_Z[1] - _P)],
}
FIN = 1.2                                # ribs inside the housings
FIN_X = (IN_X0 - 0.2, H_X[1] - 0.3)      # ribs fuse into the inner wall, stop short of the lid
FIN_Z0 = IN_Z[0] - 0.2                   # and into the floor

# --- temples --------------------------------------------------------------------
TEMPLE_T = 4.5
TEMPLE_Z = (10.0, 17.0)
TEMPLE_STRAIGHT_TO = -105.0
TEMPLE_BEND_R, TEMPLE_BEND_DEG, TEMPLE_TAIL = 45.0, 40.0, 10.0

# --- electronics ------------------------------------------------------------------
# XIAO ESP32S3 Sense on its own axes: v along the 21 mm side (0 at the far end,
# 21 at the USB-C end), w through the stack (0 at the back of the main board,
# growing towards the camera). The USB-C sits on the main board's front face,
# between the two boards; the camera module sits over the USB-C end.
XIAO_W, XIAO_L, XIAO_PCB = 17.8, 21.0, 1.0
USBC = (8.94, 3.26, 7.35)                # USB-C receptacle: width, height, length
USBC_OUT = 0.5                           # CHECK: XIAO receptacle face past the board's USB-C end
SENSE_W0, SENSE_PCB = 4.5, 1.0           # Sense board: underside above the back of the main board, thickness
SD_T = 2.5                               # microSD slot and folded camera cable on the Sense board
CAM_BASE = (9.0, 3.0)                    # CHECK: OV3660 module, side and thickness
CAM_BARREL = (7.3, 3.5)                  # CHECK: lens barrel, diameter and length
CAM_OVER = 2.0                           # CHECK: camera module sticks out past the board's USB-C end
CAM_SIDE = 0.8                           # CHECK: lens centre off the board's centre line, towards the lid
CAM_WINDOW = 8.0                         # hole in the front wall for the lens barrel
USB_PLUG = (12.5, 6.6)                   # XIAO opening in the top wall, X by Y
TOF_W, TOF_H = 18.0, 13.0                # VL53L1X breakout
TOF_DOWN_ALONG = 1.5                     # floor sensor: up the chamfer from its middle
AMP_W, AMP_H, AMP_T = 17.8, 19.3, 1.6    # MAX98357A breakout: header edge, other side, board
SPEAKER = (6.5, 35.0, 25.0)              # 3525 cavity speaker (AliExpress 1005007390381560): X, Y, Z
SPEAKER_TAB = 1.3                        # locating tab on one short end
BUTTON = (6.0, 3.5, 3.5, 1.5)            # CHECK: 6x6 button: side, body height, legs, plunger above the body
VIB = (24.0, 22.0, 1.6)                  # CHECK: vibration module board: Y, Z, thickness
VIB_MOTOR = (10.0, 2.7)
VIB_PINS = 5.6                           # its right-angle header pins, past the board's edge
BATTERY = (5.0, 37.0, 26.0)              # LiPo 300 mAh, as measured: X, Y, Z
CHARGER = (17.5, 26.2, 1.0)              # TP4056 USB-C with protection (photo): X, Y, board
CHG_USB_OUT = 1.75                       # its USB-C sticks out past the board's edge
CHG_PORT = (9.3, 3.7)                    # charger opening in the back wall, X by Z
WIRE_C = "#E8743B"

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
    top_front = cq.selectors.BoxSelector((x_range[0] - 1, y1 - 0.5, z1 - 0.5),
                                         (x_range[1] + 1, y1 + 0.5, z1 + 0.5))
    solid = solid.edges(cq.selectors.StringSyntaxSelector("|X") - top_front).fillet(max(H_R - inset, 0.6))
    return solid.edges(top_front).fillet(max(H_R_TOP_FRONT - inset, 0.4))


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
XIAO_X = IN_X0 + 3.2 + XIAO_W / 2                    # 3.2 mm channel on the inner side for the frame's wires
CAM_C = (XIAO_X + CAM_SIDE, IN_Z[1] - 0.5 - CAM_BASE[0] / 2)   # (X, Z) of the lens; module 0.5 under the top wall
XIAO_V21 = CAM_C[1] + CAM_BASE[0] / 2 - CAM_OVER     # Z of the board's USB-C end
XIAO_Z0 = XIAO_V21 - XIAO_L                          # Z of its far end
XIAO_Y0 = IN_Y[1] - (SENSE_W0 + SENSE_PCB + SD_T + CAM_BASE[1])   # Y of the back of the main board
USB_C_Y = XIAO_Y0 + XIAO_PCB + USBC[1] / 2           # Y of the middle of the XIAO's USB-C
BUTTON_Y = -20.0
SPEAKER_Y = (IN_Y[0] + SPEAKER_TAB, IN_Y[0] + SPEAKER_TAB + SPEAKER[1])   # tab on the back wall
SPEAKER_Z = (IN_Z[0] + 0.3, IN_Z[0] + 0.3 + SPEAKER[2])
SPEAKER_C = (sum(SPEAKER_Y) / 2, sum(SPEAKER_Z) / 2)  # (Y, Z)
SPEAKER_FIN_Y = SPEAKER_Y[1] + 0.3                   # rib in front of the speaker
AMP_X = (IN_X0 + 0.2, IN_X0 + 0.2 + AMP_T)           # amp stands on the inner wall, parts outwards
AMP_Y = (SPEAKER_Y[1] + 2.7, SPEAKER_Y[1] + 2.7 + AMP_H)   # speaker terminals at the back, header at the front
AMP_Z = (IN_Z[0] + 0.3, IN_Z[0] + 0.3 + AMP_W)
VIB_X = (H_X[1] - VIB[2], H_X[1])                    # board flat on the lid, motor inwards
VIB_Y = (-58.0, -58.0 + VIB[0])                      # header and pins at the front edge
VIB_Z = (-2.0, -2.0 + VIB[1])

# left housing (local, before the splay and the mirror)
TOF_FRONT_Z = 14.0
SWITCH_Y = -1.5
CHG_X = (CX - CHARGER[0] / 2, CX + CHARGER[0] / 2)
CHG_USB_Y0 = IN_Y[0] - 0.6                           # face of its USB-C, 0.6 into the back wall (1 mm left)
CHG_Y = (CHG_USB_Y0 + CHG_USB_OUT, CHG_USB_Y0 + CHG_USB_OUT + CHARGER[1])
CHG_PORT_Z = 1.5                                     # middle of the port, above the rounded bottom edge
CHG_USB_Z = (CHG_PORT_Z - USBC[1] / 2, CHG_PORT_Z + USBC[1] / 2)
CHG_Z = (CHG_USB_Z[1], CHG_USB_Z[1] + CHARGER[2])    # upside down: the board lies on its USB-C
BATTERY_X = (IN_X0 + 0.1, IN_X0 + 0.1 + BATTERY[0])
BATTERY_Y = (CHG_Y[1] + 0.3, CHG_Y[1] + 0.3 + BATTERY[1])   # its back end keeps the charger in place
BATTERY_Z = (IN_Z[1] - 0.4 - BATTERY[2], IN_Z[1] - 0.4)


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


def post(y, z):
    """Lid screw post with a 45-degree cone under it, so it prints without support."""
    p = cyl(POST_D, (H_X[1] - POST_LEN, y, z), "x", POST_LEN)
    cone = cq.Solid.makeCone(0.4, POST_D / 2, 1.6, cq.Vector(H_X[1] - POST_LEN - 1.6, y, z), cq.Vector(1, 0, 0))
    return p.union(cq.Workplane(obj=cone))


def housing(side):
    """Shell + temple of one side, built on the right; mirror the result for the left."""
    shell = housing_profile(H_X).faces(">X").shell(-WALL)
    for y, z in POSTS[side]:
        shell = shell.union(post(y, z)).cut(cyl(1.7, (H_X[1] - POST_LEN, y, z), "x", POST_LEN + 0.1))
    shell = shell.union(temple_bar())
    # wires from the groove in the frame's top rim
    shell = shell.cut(box((H_X[0] - 1, H_X[0] + WALL + 1), (GROOVE[1][0] + 0.6, GROOVE[1][1] + 0.1), GROOVE[2]))
    for y, z in tab_screws(side):
        shell = shell.cut(cyl(2.3, (H_X[0] - 0.5, y, z), "x", WALL + 1))
    return shell


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
    # shelf under the XIAO's far end (0.8 mm under it: shim with foam tape)
    s = s.union(box((FIN_X[0], XIAO_X - 0.2), (XIAO_Y0 - 0.6, IN_Y[1]), (XIAO_Z0 - 0.8 - FIN, XIAO_Z0 - 0.8)))
    # rib in front of the speaker, low so its wires pass over it
    s = s.union(fin_y(SPEAKER_FIN_Y, 6.0, (FIN_X[0], IN_X0 + SPEAKER[0] + 1.4)))
    # camera: bezel round the lens barrel, hole through the wall and the bezel
    s = s.union(cyl(11.0, (CAM_C[0], IN_Y[1], CAM_C[1]), "y", H_Y[1] + 2.2 - IN_Y[1]))
    s = s.cut(cyl(CAM_WINDOW, (CAM_C[0], IN_Y[1] - 0.5, CAM_C[1]), "y", 5.0))
    # XIAO USB-C: opening in the top wall right over the connector
    s = s.cut(box((XIAO_X - USB_PLUG[0] / 2, XIAO_X + USB_PLUG[0] / 2),
                  (USB_C_Y - USB_PLUG[1] / 2, USB_C_Y + USB_PLUG[1] / 2),
                  (IN_Z[1] - 0.5, H_Z[1] + 1)).edges("|Z").fillet(1.5))
    # button: pocket 0.6 mm into the top wall for its body, hole for the plunger
    s = s.cut(box((CX - 3.3, CX + 3.3), (BUTTON_Y - 3.3, BUTTON_Y + 3.3), (IN_Z[1] - 0.1, IN_Z[1] + 0.6)))
    s = s.cut(cyl(4.0, (CX, BUTTON_Y, IN_Z[1]), "z", WALL + 1))
    s = s.cut(grille())
    return s


def left_housing():
    """Built on the right side; the caller mirrors it."""
    s = housing(-1)
    # rib under the charger's front edge (its USB-C carries the back end)
    s = s.union(fin_y(CHG_Y[1] - 1.05, CHG_Z[0]))
    # charger USB-C: groove 0.6 mm into the back wall, open towards the lid so the
    # connector slides in, and a plug-sized hole through the 1 mm left
    s = s.cut(box((CX - USBC[0] / 2 - 0.25, H_X[1] + 1), (CHG_USB_Y0 - 0.05, IN_Y[0] + 0.5),
                  (CHG_USB_Z[0] - 0.2, CHG_USB_Z[1] + 0.2)))
    s = s.cut(box((CX - CHG_PORT[0] / 2, CX + CHG_PORT[0] / 2), (H_Y[0] - 1, IN_Y[0] + 0.1),
                  (CHG_PORT_Z - CHG_PORT[1] / 2, CHG_PORT_Z + CHG_PORT[1] / 2)).edges("|Y").fillet(CHG_PORT[1] / 2 - 0.05))
    # distance sensor windows
    s = s.cut(box((CX - 5, CX + 5), (H_Y[1] - WALL - 1, H_Y[1] + 1), (TOF_FRONT_Z - 3, TOF_FRONT_Z + 3)))
    window = box((CX - 5, CX + 5), (-WALL - 1, 1.0), (-3, 3))     # facing +Y around the origin
    s = s.cut(on_chamfer(window, TOF_DOWN_ALONG, 0))
    # switch knob
    s = s.cut(box((CX - 1.4, CX + 1.4), (SWITCH_Y - 3, SWITCH_Y + 3), (H_Z[1] - WALL - 1, H_Z[1] + 1)))
    return s


def lid(side):
    """Lid of one side, built on the right; mirror it for the left."""
    l = housing_profile((H_X[1], H_X[1] + LID_T))
    try:
        l = l.faces(">X").edges().fillet(0.8)
    except Exception:
        pass
    for y, z in POSTS[side]:
        l = l.cut(cyl(2.3, (H_X[1] - 1, y, z), "x", LID_T + 2))
    rib_x = (H_X[1] - 1.2, H_X[1] + 0.2)
    if side > 0:
        # holds the XIAO forward against the front wall (bottom strip of the board, no pads there)
        l = l.union(box((XIAO_X + 0.3, H_X[1] + 0.2), (XIAO_Y0 - 0.1 - FIN, XIAO_Y0 - 0.1),
                        (IN_Z[0] + 4.4, XIAO_Z0 + 1.8)))
        # frame for the vibration module, open at the front for its header
        g = 0.4
        l = l.union(box(rib_x, (VIB_Y[0] - g - FIN, VIB_Y[1] - 1.0), (VIB_Z[1] + g, VIB_Z[1] + g + FIN)))
        l = l.union(box(rib_x, (VIB_Y[0] - g - FIN, VIB_Y[1] - 1.0), (VIB_Z[0] - g - FIN, VIB_Z[0] - g)))
        l = l.union(box(rib_x, (VIB_Y[0] - g - FIN, VIB_Y[0] - g), (VIB_Z[0] - g - FIN, VIB_Z[1] + g + FIN)))
    else:
        # presses the charger's front edge down
        l = l.union(box((CHG_X[1] - 6.0, H_X[1] + 0.2), (CHG_Y[1] - 1.0, CHG_Y[1] - 0.15),
                        (CHG_Z[1] + 0.1, CHG_Z[1] + 4.0)))
        # keeps the battery against the inner wall
        l = l.union(box((BATTERY_X[1] + 0.2, H_X[1] + 0.2), (-24.6, -23.4), (6.0, 18.0)))
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

def bundle(points, d):
    """Wire bundle of diameter d along a polyline: cylinders with balls at the joints."""
    r = d / 2
    pts = [cq.Vector(*p) for p in points]
    solid = None
    for a, b in zip(pts, pts[1:]):
        v = b - a
        c = cq.Solid.makeCylinder(r, v.Length, a, v.normalized())
        solid = c if solid is None else solid.fuse(c)
    for p in pts:
        solid = solid.fuse(cq.Solid.makeSphere(r, p, cq.Vector(0, 0, 1), -90, 90, 360))
    return cq.Workplane(obj=solid.clean())


def xiao():
    """XIAO ESP32S3 Sense standing upright, camera forward, USB-C up."""
    x = (XIAO_X - XIAO_W / 2, XIAO_X + XIAO_W / 2)
    cx, cz = CAM_C

    def y(w):
        return XIAO_Y0 + w

    def z(v):
        return XIAO_Z0 + v

    usb_v0 = XIAO_L + USBC_OUT - USBC[2]
    sd_top = XIAO_L + CAM_OVER - CAM_BASE[0]
    cam_y0 = y(SENSE_W0 + SENSE_PCB + SD_T)
    return {
        "xiao_main": (box(x, (y(0), y(XIAO_PCB)), (z(0), z(XIAO_L))), "#1F2937"),
        "xiao_usbc": (rounded_box((XIAO_X - USBC[0] / 2, XIAO_X + USBC[0] / 2), (y(XIAO_PCB), y(XIAO_PCB + USBC[1])),
                                  (z(usb_v0), z(XIAO_L + USBC_OUT)), 0.8), "#B5BAC2"),
        "xiao_shield": (box((XIAO_X - 6.1, XIAO_X + 6.1), (y(XIAO_PCB), y(XIAO_PCB + 2.4)),
                            (z(4.0), z(usb_v0 - 0.3))), "#C7CCD4"),
        "xiao_b2b": (box((XIAO_X - 3.5, XIAO_X + 3.5), (y(XIAO_PCB + 2.4), y(SENSE_W0)), (z(1.0), z(5.0))), "#2B2B2B"),
        "xiao_sense": (box(x, (y(SENSE_W0), y(SENSE_W0 + SENSE_PCB)), (z(0), z(XIAO_L))), "#1F2937"),
        "xiao_sd": (box((XIAO_X - 7.0, XIAO_X + 7.0), (y(SENSE_W0 + SENSE_PCB), cam_y0), (z(0), z(sd_top))), "#8A8F98"),
        "camera": (box((cx - CAM_BASE[0] / 2, cx + CAM_BASE[0] / 2), (cam_y0, IN_Y[1]),
                       (cz - CAM_BASE[0] / 2, cz + CAM_BASE[0] / 2)), "#15171A"),
        "camera_lens": (cyl(CAM_BARREL[0], (cx, IN_Y[1], cz), "y", CAM_BARREL[1]), "#2A2D33"),
        "camera_glass": (cyl(4.0, (cx, IN_Y[1] + CAM_BARREL[1], cz), "y", 0.15), "#3D6FB6"),
    }


def tof(prefix):
    """VL53L1X breakout facing +Y, centred on the origin (sensor chip in front)."""
    return {
        f"{prefix}_pcb": (box((-TOF_W / 2, TOF_W / 2), (-1.0, 0.0), (-TOF_H / 2, TOF_H / 2)), "#6B3FA0"),
        f"{prefix}_chip": (box((-2.45, 2.45), (0.0, 1.56), (-1.25, 1.25)), "#111111"),
    }


def screws(side, tag):
    """M2 pan heads inside the housing, through the inner wall into the end piece."""
    return {f"screw_{tag}{i}": (cyl(3.8, (IN_X0, y, z), "x", 1.3), "#9AA0A8")
            for i, (y, z) in enumerate(tab_screws(side))}


SLOT_IN = (IN_X0 - 1.8, -1.75, 23.5)    # where the cross bundle enters a housing (inside the wall slot)


def right_wires():
    hub = (78.0, XIAO_Y0 - 2.4, 14.0)    # behind the XIAO, where its pads' wires gather
    return {
        "wire_r_cross": (bundle([SLOT_IN, (IN_X0 + 1.6, -1.75, 23.5), (IN_X0 + 1.6, XIAO_Y0 - 2.0, 23.5), hub], 2.6), WIRE_C),
        "wire_amp": (bundle([(XIAO_X + 6.8, XIAO_Y0 - 2.2, 16.0), (80.0, XIAO_Y0 - 4.2, 10.0),
                             (AMP_X[1] + 2.2, AMP_Y[1] + 1.5, 8.0)], 2.2), WIRE_C),
        "wire_button": (bundle([(74.0, XIAO_Y0 - 1.4, 11.0), (77.0, -12.0, 20.0),
                                (CX - 0.8, BUTTON_Y + BUTTON[0] / 2 + 1.3, 21.0)], 1.4), WIRE_C),
        "wire_vib": (bundle([(76.0, XIAO_Y0 - 1.9, 6.5), (84.0, -18.0, 6.0),
                             (87.5, VIB_Y[1] + VIB_PINS + 1.1, 8.5)], 1.8), WIRE_C),
    }


def left_wires():
    hub = (77.0, -2.0, 18.0)             # between the battery and the front sensor
    fy, fz = chamfer_point(TOF_DOWN_ALONG, WALL + 1.56 + 2.3)   # behind the floor sensor
    tof_back = IN_Y[1] - 1.56 - 1.0
    return {
        "wire_l_cross": (bundle([SLOT_IN, (IN_X0 + 1.8, -1.75, 23.5), hub], 2.6), WIRE_C),
        "wire_front_tof": (bundle([hub, (CX - 4.0, tof_back - 1.3, 19.0)], 1.6), WIRE_C),   # beside the switch pins
        "wire_floor_tof": (bundle([hub, (CX, -2.5, 9.0), (CX, fy, fz)], 1.6), WIRE_C),
        "wire_switch": (bundle([hub, (CX, SWITCH_Y - 1.5, 18.4)], 1.4), WIRE_C),
        "wire_charger": (bundle([(CHG_X[1] - 3.0, CHG_Y[1] - 3.0, CHG_Z[1] + 2.1), (84.0, -40.0, 21.0),
                                 (84.0, -9.0, 21.0), (82.0, -7.0, 18.0), (hub[0] + 0.5, hub[1] - 1.0, hub[2] - 1.5)], 1.8), WIRE_C),
    }


def right_electronics():
    parts = xiao()
    bz0 = IN_Z[1] + 0.6 - BUTTON[1]
    parts["button"] = (box((CX - 3, CX + 3), (BUTTON_Y - 3, BUTTON_Y + 3), (bz0, IN_Z[1] + 0.6)), "#2B2B2B")
    parts["button_cap"] = (cyl(3.5, (CX, BUTTON_Y, IN_Z[1] + 0.6), "z", BUTTON[3]), "#F5A524")
    legs = None
    for dx in (-3.25, 3.25):
        for dy in (-2.25, 2.25):
            leg = box((CX + dx - 0.35, CX + dx + 0.35), (BUTTON_Y + dy - 0.2, BUTTON_Y + dy + 0.2), (bz0 - BUTTON[2], bz0))
            legs = leg if legs is None else legs.union(leg)
    parts["button_legs"] = (legs, "#C9CDD3")
    sx = (IN_X0, IN_X0 + SPEAKER[0])
    parts["speaker"] = (rounded_box(sx, SPEAKER_Y, SPEAKER_Z, 1.5), "#1B1C1F")
    parts["speaker_tab"] = (box((CX - 6.5, CX - 3.5), (SPEAKER_Y[0] - SPEAKER_TAB, SPEAKER_Y[0]),
                                (SPEAKER_C[1] - 2.5, SPEAKER_C[1] + 2.5)), "#E6E6E6")
    parts["amp_pcb"] = (box(AMP_X, AMP_Y, AMP_Z), "#2F5DB8")
    parts["amp_chip"] = (box((AMP_X[1], AMP_X[1] + 1.0), (sum(AMP_Y) / 2 - 1.5, sum(AMP_Y) / 2 + 1.5),
                             (sum(AMP_Z) / 2 - 1.5, sum(AMP_Z) / 2 + 1.5)), "#111111")
    my, mz = VIB_Y[0] + 0.27 * VIB[0], VIB_Z[1] - 0.45 * VIB[1]
    hz = VIB_Z[1] - 0.54 * VIB[1]
    parts["vib_pcb"] = (box(VIB_X, VIB_Y, VIB_Z), "#1C2A4A")
    parts["vib_motor"] = (cyl(VIB_MOTOR[0], (VIB_X[0] - VIB_MOTOR[1], my, mz), "x", VIB_MOTOR[1]), "#D3D7DD")
    parts["vib_header"] = (box((VIB_X[0] - 2.5, VIB_X[0]), (VIB_Y[1] - 2.5, VIB_Y[1]), (hz - 3.8, hz + 3.8)), "#111111")
    parts["vib_pins"] = (box((VIB_X[0] - 1.55, VIB_X[0] - 0.95), (VIB_Y[1], VIB_Y[1] + VIB_PINS), (hz - 3.1, hz + 3.1)), "#D4AF37")
    parts["vib_parts"] = (box((VIB_X[0] - 1.0, VIB_X[0]), (VIB_Y[1] - 12.0, VIB_Y[1] - 5.0),
                              (VIB_Z[1] - 8.0, VIB_Z[1] - 2.0)), "#111111")
    parts.update(screws(+1, "r"))
    parts.update(right_wires())
    return parts


def left_electronics():
    """Built on the right side; the caller mirrors it."""
    parts = {}
    for name, (solid, colour) in tof("tof_front").items():
        y = IN_Y[1] - 1.56            # chip touches the inside of the front wall
        parts[name] = (solid.translate((CX, y, TOF_FRONT_Z)), colour)
    for name, (solid, colour) in tof("tof_down").items():
        parts[name] = (on_chamfer(solid, TOF_DOWN_ALONG, WALL + 1.56).translate((CX, 0, 0)), colour)
    parts["switch"] = (box((CX - 1.8, CX + 1.8), (SWITCH_Y - 4.3, SWITCH_Y + 4.3), (IN_Z[1] - 3.6, IN_Z[1] - 0.1)), "#2B2B2B")
    parts["switch_knob"] = (box((CX - 0.75, CX + 0.75), (SWITCH_Y - 1.0, SWITCH_Y + 1.0), (IN_Z[1], IN_Z[1] + WALL + 1.2)), "#E8E8E8")
    parts["switch_pins"] = (box((CX - 0.4, CX + 0.4), (SWITCH_Y - 2.4, SWITCH_Y + 2.4), (IN_Z[1] - 7.1, IN_Z[1] - 3.6)), "#C9CDD3")
    parts["charger_pcb"] = (box(CHG_X, CHG_Y, CHG_Z), "#2F5DB8")
    parts["charger_usb"] = (rounded_box((CX - USBC[0] / 2, CX + USBC[0] / 2), (CHG_USB_Y0, CHG_USB_Y0 + USBC[2]),
                                        CHG_USB_Z, 0.8), "#B5BAC2")
    parts["charger_parts"] = (box((CX - 6.0, CX + 6.0), (CHG_Y[0] + 6.7, CHG_Y[1] - 3.0), (CHG_Z[0] - 1.6, CHG_Z[0])), "#111111")
    pads = None
    for dx in (1.9, 5.3, 12.2, 15.6):            # OUT+, B+, B-, OUT- at the front end, soldered from the top
        p = box((CHG_X[0] + dx - 0.9, CHG_X[0] + dx + 0.9), (CHG_Y[1] - 3.35, CHG_Y[1] - 1.55), (CHG_Z[1], CHG_Z[1] + 0.8))
        pads = p if pads is None else pads.union(p)
    parts["charger_pads"] = (pads, "#C9CDD3")
    parts["battery"] = (rounded_box(BATTERY_X, BATTERY_Y, BATTERY_Z, 1.5), "#B9BFC8")
    parts.update(screws(-1, "l"))
    parts.update(left_wires())
    return parts


# ---------------------------------------------------------------- build

def build():
    r_house, l_house = right_housing(), left_housing()
    r_lid, l_lid = lid(+1), lid(-1)
    frame = frame_front()
    local = {   # un-splayed, for the printer
        "frame_front": frame,
        "temple_right": r_house,
        "lid_right": r_lid,
        "temple_left": mirror(l_house),
        "lid_left": mirror(l_lid),
    }
    printed = {   # in the assembly position
        "frame_front": frame,
        "temple_right": place(r_house),
        "lid_right": place(r_lid),
        "temple_left": mirror(place(l_house)),
        "lid_left": mirror(place(l_lid)),
    }
    clear = {"lens_right": lens(1), "lens_left": lens(-1)}
    pads = {}
    elec = {name: (place(s), c) for name, (s, c) in right_electronics().items()}
    elec.update({name: (mirror(place(s)), c) for name, (s, c) in left_electronics().items()})
    # the bundle across the frame, in the groove at the back of the top rim
    x_end = SLOT_IN[0]
    elec["wire_frame"] = (bundle([(-x_end, SLOT_IN[1], SLOT_IN[2]), (x_end, SLOT_IN[1], SLOT_IN[2])], 2.6), WIRE_C)
    return local, printed, clear, pads, elec


PRINT_ROT = {   # how each part lies on the printer bed: (axis, degrees) about the origin
    "frame_front": ("x", -90),      # front face down
    "temple_right": ("y", -90),     # open side up, temple flat
    "lid_right": ("y", 90),         # outer face down, ribs up
    "temple_left": ("y", 90),
    "lid_left": ("y", -90),
}


def for_printer(name, wp):
    axis, deg = PRINT_ROT[name]
    end = {"x": (1, 0, 0), "y": (0, 1, 0)}[axis]
    wp = wp.rotate((0, 0, 0), end, deg)
    bb = wp.val().BoundingBox()
    return wp.translate((-(bb.xmin + bb.xmax) / 2, -(bb.ymin + bb.ymax) / 2, -bb.zmin))


def collisions(named):
    """Pairs of solids whose overlap is more than a speck (wires may touch each other)."""
    items = list(named.items())
    hits = []
    for i, (na, a) in enumerate(items):
        ba = a.val().BoundingBox()
        for nb, b in items[i + 1:]:
            if na.startswith("wire_") and nb.startswith("wire_"):
                continue
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
    1: "camera", 2: "tof_front_pcb", 3: "tof_down_pcb", 4: "speaker", 5: "vib_pcb",
    6: "battery", 7: "button_cap", 8: "switch_knob", 9: "frame_front",
    10: "charger_pcb", 11: "xiao_usbc", 12: "charger_usb", 13: "wire_frame",
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
    for name, (wp, colour) in elec.items():
        assy.add(wp, name=name, color=cq.Color(colour))
    assy.export(str(OUT / "baseera_glasses.step"))
    lens_dxf(OUT / "lenses.dxf")

    parts = []
    for name, wp in printed.items():
        parts.append(("print", name, frame_colour, wp))
    for name, wp in clear.items():
        parts.append(("lens", name, "#3A4150", wp))
    for name, (wp, colour) in elec.items():
        parts.append(("wire" if name.startswith("wire_") else "elec", name, colour, wp))

    model = {"parts": [], "labels": {}}
    for group, name, colour, wp in parts:
        pos, idx, n = mesh(wp)
        side = "left" if wp.val().BoundingBox().center.x < -20 else "right" if wp.val().BoundingBox().center.x > 20 else "mid"
        model["parts"].append({"name": name, "group": group, "color": colour, "side": side, "pos": pos, "idx": idx})
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
    print(f"XIAO USB-C opening centre (local): X {XIAO_X:.2f}, Y {USB_C_Y:.2f}; receptacle face "
          f"{H_Z[1] - XIAO_V21 - USBC_OUT:.1f} mm under the top")
    print(f"camera lens centre (local): X {CAM_C[0]:.2f}, Z {CAM_C[1]:.2f}; charger port centre: X {CX:.2f}, Z {CHG_PORT_Z:.2f}")
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
