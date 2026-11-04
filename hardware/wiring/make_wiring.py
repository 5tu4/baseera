"""Wiring diagram for the Baseera glasses, stage 1 -> wiring.html + wiring-diagram.pdf (+ wiring_stage1.png/.svg, page 1).

Stage 1 parts (user, 2026-11-03): Seeed XIAO ESP32S3 Sense, the vibration motor module (IN VCC GND header, own
transistor), the TP4056 USB-C charger with protection (pads OUT+ B+ B- OUT- at one end, IN + - at the USB-C end), the
SS12D00 slide switch and the 300 mAh LiPo (5 x 26 x 37 mm). Optional: a 2 x 100 kOhm divider so the app can read the
battery level.

Power path (user's switch wiring, corrected 2026-11-03): battery -> TP4056 B+/B-; TP4056 OUT+ -> switch middle leg;
switch side leg -> XIAO BAT+ (not 5V: the XIAO's 5V pin is its USB-C line); TP4056 OUT- -> XIAO BAT- (not B-: the
protection stays in the circuit). The TP4056 charges with the switch off too; the switch only cuts the XIAO.

Sheet laid out as the glasses are seen from the front: the right temple (XIAO, module) on the left, the left temple
(charger, switch, battery) on the right; W5 and W6 cross the frame in the groove. The XIAO is drawn from the back of
its main board, the side the wires are soldered on (pads in mirror order of Seeed's pinout, BAT- nearer the USB-C);
the module as printed; the TP4056 turned round so its pads face the battery. Every pad on the other parts takes ONE
wire; only the XIAO's pads take more. W/B numbers match the wire list on page 2. Where two wires cross, the one on top
has a white edge: they are not joined.
Pins follow firmware/baseera_glasses/config.h: motor IN on D8 (GPIO 7), battery sense on D0/A0 (GPIO 1).
Run: python make_wiring.py
"""
import pathlib
import subprocess

HERE = pathlib.Path(__file__).resolve().parent
EDGE = r"C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe"
EDGE_PROFILE = (HERE / "../../app/build/tmp/edge-profile").resolve()

# ---------------------------------------------------------------- colours
C = {
    "bat": "#d32f2f",   # battery +
    "gnd": "#1b1b1b",   # GND / battery -
    "v33": "#ef6c00",   # 3.3 V
    "sig": "#7b1fa2",   # motor control (purple)
}

# ---------------------------------------------------------------- pins
P = {}


def pins(prefix, x, ys, names):
    for n, y in zip(names, ys):
        P[f"{prefix}.{n}"] = (x, y)


# XIAO, back of the main board, 12 px per mm: 17.8 x 21 mm board, pads 2.54 mm apart.
X_L, X_R, X_T, X_B = 360, 574, 210, 462
X_C = (X_L + X_R) // 2
X_Y = [245, 275, 306, 336, 367, 397, 428]
BACK_LEFT = ["5V", "GND", "3V3", "D10", "D9", "D8", "D7"]     # Seeed's right column, seen from the back
BACK_RIGHT = ["D0", "D1", "D2", "D3", "D4", "D5", "D6"]       # Seeed's left column, seen from the back
pins("X", X_L, X_Y, BACK_LEFT)
pins("X", X_R, X_Y, BACK_RIGHT)
P["X.BAT-"], P["X.BAT+"] = (X_C + 5, 300), (X_C + 5, 350)      # wire ends, inside the pads

# Vibration module, as printed: header on the right edge, pins sticking out.
pins("M", 272, [325, 350, 375], ["IN", "VCC", "GND"])

# TP4056, turned round: pads on its left edge (OUT- B- B+ OUT+ top to bottom), USB-C on the right.
TP_L, TP_T, TP_R, TP_B = 870, 300, 1060, 440
pins("TP", TP_L + 10, [315, 342, 398, 425], ["OUT-", "B-", "B+", "OUT+"])

# Battery: leads come out of its right end.
P["BAT.-"], P["BAT.+"] = (790, 342), (790, 398)

# Slide switch, legs up (pads above the body).
P["SW.A"], P["SW.MID"], P["SW.B"] = (772, 508), (797, 508), (822, 508)

# ---------------------------------------------------------------- wires
# (id, colour, waypoints from pad to pad, segment that carries the tag)
W = [
    ("W1", "gnd", ["M.GND", (300, 375), (300, 275), "X.GND"], 2),
    ("W2", "v33", ["M.VCC", (322, 350), (322, 306), "X.3V3"], 2),
    ("W3", "sig", ["M.IN", (344, 325), (344, 397), "X.D8"], 1),
    ("B1", "bat", ["BAT.+", "TP.B+"], 0),
    ("B2", "gnd", ["BAT.-", "TP.B-"], 0),
    ("W4", "bat", ["TP.OUT+", (848, 425), (848, 478), (797, 478), "SW.MID"], 2),
    ("W5", "bat", ["SW.A", (772, 490), (680, 490), (680, 630), (X_C + 28, 630), (X_C + 28, 350), "X.BAT+"], 3),
    ("W6", "gnd", ["TP.OUT-", (848, 315), (848, 270), (660, 270), (660, 614), (X_C + 43, 614), (X_C + 43, 300),
                   "X.BAT-"], 2),
]
TAG_AT = {"W5": (600, 630), "W6": (600, 614)}
TAG_SHIFT = {"W6": (0, -16), "W5": (0, 16)}      # the two cross-frame wires run side by side


def pt(p):
    return P[p] if isinstance(p, str) else p


def path_d(points, r=7):
    pts = [pt(p) for p in points]
    d = f"M{pts[0][0]},{pts[0][1]}"
    for i in range(1, len(pts) - 1):
        (x0, y0), (x1, y1), (x2, y2) = pts[i - 1], pts[i], pts[i + 1]

        def towards(ax, ay, bx, by, dist):
            L = max(1e-6, ((bx - ax) ** 2 + (by - ay) ** 2) ** 0.5)
            dist = min(dist, L / 2)
            return ax + (bx - ax) * dist / L, ay + (by - ay) * dist / L
        a = towards(x1, y1, x0, y0, r)
        b = towards(x1, y1, x2, y2, r)
        d += f" L{a[0]:.1f},{a[1]:.1f} Q{x1},{y1} {b[0]:.1f},{b[1]:.1f}"
    d += f" L{pts[-1][0]},{pts[-1][1]}"
    return d


def tag(x, y, text, col, dashed=False):
    dash = ' stroke-dasharray="3 2"' if dashed else ""
    return (f'<g class="tag"><rect x="{x-15}" y="{y-8}" width="30" height="16" rx="8" stroke="{C[col]}"{dash}/>'
            f'<text x="{x}" y="{y+4}">{text}</text></g>')


def wire(points, col, dashed=False):
    d = path_d(points)
    dash = ' stroke-dasharray="7 5"' if dashed else ""
    return f'<path d="{d}" class="case"/><path d="{d}" class="wire" stroke="{C[col]}"{dash}/>'


def wires_svg():
    out = [wire(pts, col) for _, col, pts, _ in W]        # white casing: crossings show as bridges
    for wid, col, pts, lab in W:
        if wid in TAG_AT:
            x, y = TAG_AT[wid]
        else:
            a, b = pt(pts[lab]), pt(pts[lab + 1])
            x, y = (a[0] + b[0]) / 2, (a[1] + b[1]) / 2
        out.append(tag(x, y, wid, col))
    return "\n".join(out)


def pad(x, y, used=True, hole=True, castellated=False):
    cls = "pad" if used else "pad unused"
    if castellated:   # half hole on the board edge
        return (f'<rect x="{x-7}" y="{y-8}" width="14" height="16" rx="3" class="{cls}"/>'
                f'<circle cx="{x}" cy="{y}" r="3.2" class="edgehole"/>')
    return f'<circle cx="{x}" cy="{y}" r="5.5" class="{cls}"/>' + (f'<circle cx="{x}" cy="{y}" r="2" class="hole"/>' if hole else "")


def label(x, y, text, anchor="start", cls="pinlab"):
    return f'<text x="{x}" y="{y+4}" text-anchor="{anchor}" class="{cls}">{text}</text>'


def resistor(x, y0, y1):
    """Zig-zag resistor from (x, y0) down to (x, y1)."""
    n = 8
    pts = [(x, y0)] + [(x + (7 if i % 2 else -7), y0 + (y1 - y0) * (i + 0.5) / n) for i in range(n)] + [(x, y1)]
    d = "M" + " L".join(f"{a:.1f},{b:.1f}" for a, b in pts)
    return f'<path d="{d}" class="resistor"/>'


def boards_svg():
    s = []
    # ---- the two temples
    s.append('<rect x="14" y="96" width="600" height="512" rx="10" class="zone"/>')
    s.append('<text x="28" y="116" class="zonename">RIGHT TEMPLE</text>')
    s.append('<rect x="632" y="250" width="454" height="330" rx="10" class="zone"/>')
    s.append('<text x="1072" y="572" class="zonename" text-anchor="end">LEFT TEMPLE</text>')
    s.append('<text x="470" y="660" class="small">W5, W6 cross the frame in the groove behind its top rim</text>')

    # ---- XIAO ESP32S3, back of the main board, USB-C at the top
    used = {"GND", "3V3", "D8"}
    s.append(f'<text x="{X_L}" y="150" class="title">XIAO ESP32S3 Sense · back of the main board</text>')
    s.append(f'<text x="{X_L}" y="165" class="small">the side you solder on; camera board on the other side</text>')
    s.append(f'<rect x="{X_L}" y="{X_T}" width="{X_R - X_L}" height="{X_B - X_T}" rx="10" class="pcb-black"/>')
    s.append(f'<rect x="{X_C - 54}" y="190" width="108" height="34" rx="8" class="usb"/>')
    s.append(f'<text x="{X_C}" y="211" class="small" text-anchor="middle">USB-C (programming)</text>')
    for n, y in zip(BACK_LEFT, X_Y):
        s.append(pad(X_L, y, n in used, castellated=True))
        s.append(label(X_L + 12, y, n, cls="pinlab light" if n in used else "pinlab dim"))
    for n, y in zip(BACK_RIGHT, X_Y):
        s.append(pad(X_R, y, False, castellated=True))
        s.append(label(X_R - 12, y, n + (" / A0" if n == "D0" else ""), "end", "pinlab dim"))
    for n in ("BAT-", "BAT+"):
        x, y = P[f"X.{n}"]
        s.append(f'<rect x="{x - 22}" y="{y - 10}" width="34" height="20" rx="3" class="pad"/>')
        s.append(label(x - 30, y, n.replace("-", "−"), "end", "pinlab light"))
    s.append(f'<text x="{X_C - 27}" y="452" class="boardname" text-anchor="middle">XIAO ESP32S3</text>')
    s.append(f'<text x="{X_L}" y="486" class="small">5V pin: leave empty</text>')
    s.append(f'<text x="{X_L}" y="500" class="small">(it is the USB-C line)</text>')

    # ---- vibration module, as printed (motor on the left, header on the right)
    s.append('<text x="30" y="214" class="title">Vibration motor module · as printed</text>')
    s.append('<text x="30" y="229" class="small">header pins IN · VCC · GND, top to bottom</text>')
    s.append('<rect x="30" y="245" width="220" height="220" rx="12" class="pcb-navy"/>')
    s.append('<circle cx="104" cy="350" r="46" class="motor"/>')
    s.append('<text x="104" y="354" class="small light" text-anchor="middle">motor</text>')
    for cx, cy in ((226, 268), (226, 442)):
        s.append(f'<circle cx="{cx}" cy="{cy}" r="10" class="mhole"/>')
    s.append('<rect x="166" y="282" width="18" height="10" rx="1" class="res"/>')
    s.append('<rect x="170" y="402" width="14" height="10" rx="1" class="chip"/>')
    s.append('<rect x="228" y="310" width="22" height="80" rx="2" class="chip"/>')       # header plastic
    for n in ("IN", "VCC", "GND"):
        x, y = P[f"M.{n}"]
        s.append(f'<line x1="250" y1="{y}" x2="{x}" y2="{y}" class="pin"/>')
        s.append(pad(x, y, hole=False))
        s.append(label(220, y, n, "end", "pinlab light"))
    s.append('<text x="30" y="484" class="small">its own transistor drives the motor: IN high = vibrate</text>')
    s.append('<text x="30" y="498" class="small">solder the wires onto the 3 header pins (or cut them short first)</text>')
    s.append('<text x="30" y="530" class="title">On the XIAO</text>')
    for i, t in enumerate(["Pads are counted from the USB-C end. Seen from the back, the left",
                           "edge is 5V, GND, 3V3, D10, D9, D8, D7 and the right edge D0 to D6.",
                           "BAT− is the battery pad nearer the USB-C: confirm it with the",
                           "beep test on page 2 before the battery goes on."]):
        s.append(f'<text x="30" y="{546 + i * 14}" class="small">{t}</text>')

    # ---- TP4056 USB-C charger, turned round: pads face the battery
    s.append(f'<text x="{TP_L}" y="292" class="title">TP4056 USB-C charger, 6 pads</text>')
    s.append(f'<rect x="{TP_L}" y="{TP_T}" width="{TP_R - TP_L}" height="{TP_B - TP_T}" rx="6" class="pcb-blue"/>')
    s.append(f'<rect x="{TP_R - 14}" y="345" width="40" height="50" rx="7" class="usb"/>')
    s.append(f'<text x="{TP_R - 30}" y="338" class="small light" text-anchor="end">USB-C (charging)</text>')
    s.append('<rect x="960" y="352" width="40" height="34" rx="3" class="chip"/>')
    s.append('<rect x="972" y="396" width="16" height="9" rx="1" class="res"/>')
    s.append('<text x="980" y="420" class="r3" text-anchor="middle">R3 → 4.7 kΩ</text>')
    for n in ("OUT-", "B-", "B+", "OUT+"):
        x, y = P[f"TP.{n}"]
        s.append(pad(x, y))
        s.append(label(x + 12, y, n.replace("-", "−"), "start", "pinlab light"))
    for y, n in ((312, "+"), (428, "−")):
        s.append(pad(TP_R - 24, y, used=False))
        s.append(label(TP_R - 34, y, n, "end", "pinlab dim"))
    s.append(f'<text x="{TP_L}" y="456" class="small">drawn turned round: pads face the battery</text>')
    s.append(f'<text x="{TP_L}" y="470" class="small">+ − at the USB-C end (USB input): not used</text>')

    # ---- battery, leads out of its right end
    s.append('<rect x="700" y="300" width="90" height="140" rx="8" class="battery"/>')
    s.append('<rect x="778" y="330" width="12" height="80" rx="3" class="pcb-blue"/>')
    for i, t in enumerate(["LiPo", "3.7 V", "300 mAh", "5×26×37"]):
        s.append(f'<text x="738" y="{344 + i * 16}" class="small" text-anchor="middle">{t}</text>')
    s.append('<text x="738" y="424" class="small" text-anchor="middle">red +, black −</text>')

    # ---- slide switch, legs up; ON = slider toward A
    s.append('<rect x="758" y="518" width="78" height="22" rx="3" class="switch"/>')
    s.append('<rect x="764" y="540" width="18" height="10" rx="2" class="knob"/>')
    for x, n, lab in ((772, "A", "A"), (797, "MID", "mid"), (822, "B", "B")):
        s.append(pad(x, 508, used=(n != "B"), hole=False))
        s.append(f'<text x="{x}" y="534" class="small" text-anchor="middle">{lab}</text>')
    s.append('<text x="758" y="566" class="title">Slide switch SS12D00</text>')
    s.append('<text x="900" y="526" class="small">ON = slider toward A</text>')
    s.append('<text x="900" y="540" class="small">leg B unused</text>')

    # ---- optional: battery level divider (top right)
    s.append('<rect x="632" y="40" width="454" height="196" rx="8" class="optbox"/>')
    s.append('<text x="646" y="60" class="title">Optional · battery level (2 × 100 kΩ), on the XIAO</text>')
    s.append('<text x="646" y="75" class="small">lets the app read the battery %</text>')
    rx = 700
    s.append(f'<text x="{rx}" y="100" class="pinlab" text-anchor="middle">XIAO BAT+</text>')
    s.append(wire([(rx, 106), (rx, 114)], "bat", True))
    s.append(resistor(rx, 114, 148))
    s.append(wire([(rx, 148), (rx, 162)], "sig", True))
    s.append(f'<circle cx="{rx}" cy="162" r="4" class="node"/>')
    s.append(wire([(rx, 162), (rx + 46, 162)], "sig", True))
    s.append(f'<text x="{rx + 54}" y="166" class="pinlab">XIAO D0 / A0</text>')
    s.append(resistor(rx, 170, 204))
    s.append(f'<text x="{rx}" y="222" class="pinlab" text-anchor="middle">XIAO BAT−</text>')
    s.append(tag(rx + 40, 131, "R1", "bat", True))
    s.append(tag(rx + 40, 187, "R2", "gnd", True))
    for i, t in enumerate(["R1: BAT+ to D0 (1st pad, right edge)", "R2: D0 to BAT−", "Sleeve the resistor legs.",
                           "Not fitted: set HAS_BATTERY_SENSE 0", "in firmware config.h."]):
        s.append(f'<text x="862" y="{112 + i * 15}" class="small">{t}</text>')
    return "\n".join(s)


CSS = """
@page { size: A4 landscape; margin: 9mm; }
* { box-sizing: border-box; }
body { font-family: "Segoe UI", Arial, sans-serif; color:#1f2328; margin:0; font-size:10.5pt; background:#fff; }
h1 { font-size:17pt; margin:0 0 1mm; }
h2 { font-size:13pt; margin:4mm 0 2mm; color:#0f4c81; }
.sub { color:#5b6470; margin:0 0 2mm; font-size:9.5pt; }
.page { break-after: page; }
.page:last-child { break-after: auto; }
svg.diagram { display:block; width:100%; height:150mm; }
.case { fill:none; stroke:#fff; stroke-width:7; stroke-linecap:round; stroke-linejoin:round; }
.wire { fill:none; stroke-width:3.2; stroke-linecap:round; stroke-linejoin:round; }
.tag rect { fill:#fff; stroke-width:1.6; }
.tag text { font-size:10px; font-weight:700; text-anchor:middle; fill:#1f2328; }
.optbox { fill:#f6f8fa; stroke:#9aa7b4; stroke-dasharray:5 4; }
.zone { fill:none; stroke:#c5ced8; stroke-width:1.2; }
.zonename { font-size:10px; font-weight:700; fill:#7a8794; letter-spacing:1px; }
.pad { fill:#d9a441; stroke:#8a6417; stroke-width:1; }
.pad.unused { fill:#5a5a5a; stroke:#444; }
.hole { fill:#2a2a2a; } .edgehole { fill:#fff; }
.pin { stroke:#d9a441; stroke-width:3; }
.pcb-black { fill:#22252a; } .pcb-blue { fill:#1e5aa8; } .pcb-navy { fill:#1c2a4a; }
.usb { fill:#c9ccd1; stroke:#8b9097; } .chip { fill:#111; }
.mhole { fill:#fff; stroke:#d9a441; stroke-width:2; }
.motor { fill:#3b3b3b; stroke:#888; } .battery { fill:#d8dde4; stroke:#8b9097; }
.switch { fill:#b9bec6; stroke:#7d838b; } .knob { fill:#222; }
.res { fill:#111; stroke:#ffcc33; stroke-width:1.5; }
.r3 { font-size:10px; font-weight:700; fill:#ffd54f; }
.resistor { fill:none; stroke:#1f2328; stroke-width:2; stroke-linejoin:round; }
.node { fill:#1f2328; }
.pinlab { font-size:11px; font-weight:700; fill:#1f2328; } .light { fill:#fff; } .dim { fill:#8c8c8c; font-weight:400; }
.boardname { font-size:13px; font-weight:700; fill:#fff; }
.small { font-size:10px; fill:#3d4650; } .small.light { fill:#e8eef7; } .title { font-size:11.5px; font-weight:700; fill:#0f4c81; }
.legend { display:flex; flex-wrap:wrap; gap:2mm 6mm; margin:1mm 0 2mm; font-size:9.5pt; }
.legend span { display:inline-flex; align-items:center; gap:2mm; }
.legend i { display:inline-block; width:10mm; height:3.2mm; border-radius:2mm; }
.legend i.dash { background:none; height:0; border-top:3px dashed #d32f2f; border-radius:0; }
.alert { border:1.5px solid #d32f2f; background:#fff4f4; border-radius:2mm; padding:2mm 3mm; margin:2mm 0; }
.cols { display:flex; gap:6mm; } .cols > div { flex:1; }
table { width:100%; border-collapse:collapse; font-size:8.8pt; }
.p2 .cols { font-size:9pt; line-height:1.4; } .p2 h1 { margin-bottom:0; } .p2 h2 { margin:2.5mm 0 1mm; font-size:12pt; } .p2 li { margin-bottom:0.6mm; }
th, td { border:1px solid #cfd6dd; padding:0.7mm 2mm; text-align:left; vertical-align:top; }
th { background:#eaf1f7; }
tr.opt td { color:#5b6470; background:#fafbfc; }
td.sw { width:8mm; } td.sw i { display:inline-block; width:7mm; height:3mm; border-radius:1.5mm; }
ol { margin:1mm 0; padding-left:6mm; } li { margin-bottom:1.2mm; }
.note { color:#5b6470; font-size:9pt; }
"""

ROWS = [
    # id, colour key, colour name, from, to, note, optional
    ("W1", "gnd", "black", "module GND", "XIAO GND (2nd pad from the USB-C)", "right temple", False),
    ("W2", "v33", "orange", "module VCC", "XIAO 3V3 (3rd pad)", "the motor is rated 3 V", False),
    ("W3", "sig", "purple", "module IN", "XIAO D8 (6th pad)", "HIGH = vibrate (GPIO 7)", False),
    ("B1", "bat", "battery red", "LiPo red (+)", "TP4056 B+", "battery's own lead; solder this LAST (page 3)", False),
    ("B2", "gnd", "battery black", "LiPo black (−)", "TP4056 B−", "battery's own lead; solder LAST", False),
    ("W4", "bat", "red", "TP4056 OUT+", "switch MIDDLE leg", "left temple", False),
    ("W5", "bat", "red", "switch leg A", "XIAO BAT+ (battery pad farther from the USB-C)",
     "across the frame; NOT the XIAO's 5V pin", False),
    ("W6", "gnd", "black", "TP4056 OUT−", "XIAO BAT− (battery pad nearer the USB-C)",
     "across the frame; OUT−, not B−", False),
    ("R1", "bat", "100 kΩ", "XIAO BAT+", "XIAO D0 / A0", "optional battery level; resistor legs, sleeved", True),
    ("R2", "gnd", "100 kΩ", "XIAO D0 / A0", "XIAO BAT−", "optional battery level", True),
]


def page2():
    rows = "".join(
        f"<tr class='{'opt' if opt else ''}'><td><b>{i}</b></td><td class='sw'><i style='background:{C[k]}'></i></td>"
        f"<td>{cn}</td><td>{a}</td><td>{b}</td><td class='note'>{n}</td></tr>"
        for i, k, cn, a, b, n, opt in ROWS)
    return f"""
<div class="page p2">
<h1>Wire list — Baseera glasses, stage 1</h1>
<p class="sub">8 connections: W1–W3 in the right temple, B1, B2 and W4 in the left temple, W5 and W6 across the frame;
R1 and R2 (grey) are optional. Every pad on the module, charger, switch and battery takes one wire; only the XIAO's pads
take more: <b>BAT+ 2</b> (W5, R1) and <b>BAT− 2</b> (W6, R2) when R1/R2 are fitted.</p>
<table><tr><th>#</th><th></th><th>Wire</th><th>From</th><th>To</th><th>Note</th></tr>{rows}</table>
<div class="cols">
<div>
<h2>Wire and length</h2>
<ul>
<li>28–30 AWG silicone wire (BOM item 12), colours as above. If a colour is missing, use any colour and put a tape tag with
the number on both ends.</li>
<li><b>W1–W3, right temple</b>: XIAO at the front of the right housing, module in the frame on its lid. About 8 cm each,
so the lid can lie open beside the housing.</li>
<li><b>B1, B2, W4, left temple</b>: the charger lies at the back, the battery in front of it, the switch under the top wall
at the front. B1 and B2 are the battery's own leads: shorten them to reach the charger's pads. W4 about 9 cm.</li>
<li><b>W5, W6, across the frame</b>: out of the left housing's wire slot, along the groove behind the frame's top rim, into
the right housing's slot, to the back of the XIAO. W5 about 20 cm, W6 about 28 cm (it starts at the charger at the back),
twisted loosely together.</li>
<li><b>On the XIAO's back</b>: strip 2 mm, tin, and lay each wire flat towards the back of the housing. Nothing may stand
out past the board's edge by more than 2 mm: the channel beside the XIAO is 3.2 mm wide.</li>
</ul>
</div>
<div>
<h2>Checks before the battery goes on</h2>
<ol>
<li><b>Which XIAO battery pad is which</b> (beep test): <b>XIAO GND ↔ BAT−</b> must beep; <b>GND ↔ BAT+</b> must not.</li>
<li><b>XIAO 3V3 ↔ GND</b> must not beep (a short chirp as the capacitors charge is normal; a steady beep is a short).</li>
<li>Switch OFF: <b>TP4056 OUT+ ↔ XIAO BAT+</b> must not beep. Switch ON (toward A): it must beep.</li>
<li><b>TP4056 OUT− ↔ XIAO GND</b> must beep.</li>
<li>Every row of the table: beep from the "From" end to the "To" end.</li>
<li>The battery itself: <b>red lead to black lead reads 3.0–4.2 V</b>. A minus sign means the colours are swapped: stop.</li>
<li>After the battery is on, switch OFF: <b>OUT+ to OUT−</b> reads the battery's voltage. If it reads 0 V, plug the
charger's USB-C in once: that wakes the protection.</li>
</ol>
<div class="alert">Never let the battery leads touch. Solder red to B+ first with the black lead taped. Nothing goes on the
XIAO's 5V pin: it is wired to the XIAO's USB-C. One USB cable at a time while the switch is ON (the XIAO's USB-C also
charges the battery through W5).</div>
</div>
</div>
</div>"""


def page3():
    return """
<div class="page p2">
<h1>Build order and the charger fix</h1>
<div class="cols">
<div>
<h2>1 · Charger fix (before anything else)</h2>
<div class="alert">This TP4056 board charges at <b>1 A</b>. The 300 mAh battery should get no more than about 0.3 A.
Swap resistor <b>R3</b> (1.2 kΩ, marked <b>122</b>, next to the chip) for a <b>4.7 kΩ</b> resistor: about 250 mA.</div>
<ol>
<li>Measure R3 first: about 1.2 kΩ (a little less is normal on the board). <b>If it reads something else, don't remove
it</b>: send a photo of the board first.</li>
<li>Heat R3 and lift it off (a blob of solder across both ends helps).</li>
<li>Solder the 4.7 kΩ resistor's legs (bent short) onto the two R3 pads and trim them.</li>
<li>Measure across the pads again: about 4.7 kΩ.</li>
</ol>
<h2>2 · Order of work</h2>
<ol>
<li>Charger fix (above).</li>
<li><b>Firmware</b> over the XIAO's USB-C: <span style="font-family:Consolas">firmware/baseera_glasses</span>, stage 1 in
config.h (HAS_SPEAKER, HAS_DISTANCE, HAS_BUTTON 0; HAS_BATTERY_SENSE 0 unless R1/R2 are fitted).</li>
<li><b>Bench test</b>: W1–W3 with the parts on the table, USB power only. At start-up the module gives one short buzz;
then in the app join Wi-Fi Baseera-XXXX, connect, Test vibration.</li>
<li>Parts into the housings (right column). Solder W4 in the left temple.</li>
<li>Solder W5 and W6 to the XIAO's battery pads, thread them out through the right housing's slot, along the groove and in
through the left housing's slot, then solder W5 to the switch's leg A and W6 to the charger's OUT−.</li>
<li>Checks on page 2, switch OFF, no battery.</li>
<li><b>Battery last</b>: tape the black lead, solder red to B+, then untape and solder black to B−.</li>
<li>Switch ON without USB: one short buzz means it runs on the battery.</li>
</ol>
</div>
<div>
<h2>3 · Where each part sits (printed temples v4)</h2>
<ul>
<li><b>Right housing:</b> XIAO at the front, camera lens in the bezel, its USB-C under the top opening (programming).</li>
<li><b>Right lid:</b> vibration module in the printed frame, header edge forward, motor facing into the housing.</li>
<li><b>Left housing, back:</b> charger upside down near the floor, its USB-C in the groove of the back wall. The front edge
rests on the rib; the rib on the lid holds it down.</li>
<li><b>Left housing, middle:</b> battery standing on the inner wall (foam tape), lead end towards the charger's pads.</li>
<li><b>Left housing, top front:</b> switch under the slot in the top wall (hot glue), right next to the wire slot.</li>
</ul>
<h2>4 · Good to know</h2>
<ul>
<li><b>Charging</b>: through the charger's USB-C in the back of the left temple, with the switch OFF or ON (red light =
charging, blue/green = full). The switch only cuts the XIAO.</li>
<li>The XIAO's 5V pin is its USB-C line, so the battery goes to <b>BAT+</b>, the XIAO's own battery input.</li>
<li>OUT− (not B−) goes to the XIAO, so the charger's protection still cuts off a flat or shorted battery.</li>
<li>D8 is shared with the camera board's microSD slot: leave the slot empty.</li>
<li>The XIAO, its camera and Wi-Fi draw roughly 200–300 mA (estimate), so the 300 mAh battery lasts about an hour of use.</li>
<li>When the phone link drops, the glasses buzz long-short-long by themselves.</li>
</ul>
<p class="note">Printed parts and their placement: <span style="font-family:Consolas">hardware/cad/PRINTING.md</span>.</p>
</div>
</div>
</div>"""


def build():
    legend = "".join(
        f"<span><i style='background:{C[k]}'></i>{t}</span>" for k, t in [
            ("bat", "battery +"), ("gnd", "GND / battery −"), ("v33", "3.3 V"), ("sig", "motor control")])
    legend += "<span><i class='dash'></i>optional</span>"
    svg_body = f'{boards_svg()}{wires_svg()}'
    svg = f'<svg class="diagram" viewBox="0 0 1100 690" xmlns="http://www.w3.org/2000/svg">{svg_body}</svg>'
    html = f"""<!doctype html><html lang="en"><head><meta charset="utf-8"><title>Baseera glasses wiring</title>
<style>{CSS}</style></head><body>
<div class="page">
<h1>Baseera glasses — wiring diagram, stage 1</h1>
<p class="sub">XIAO ESP32S3 Sense, vibration module, TP4056 USB-C charger, slide switch and 300 mAh LiPo, laid out as the
glasses are seen from the front (right temple on the left). The XIAO is drawn from the back of its main board, where the
wires are soldered: count its pads from the USB-C end. The module is drawn as printed, the charger turned round. Always
solder by the printed pad name. Wire numbers match the wire list on page 2. Where two wires cross, the one drawn on top
has a white edge: they are not joined.</p>
<div class="legend">{legend}</div>
{svg}
</div>
{page2()}
{page3()}
</body></html>"""
    out = HERE / "wiring.html"
    out.write_text(html, encoding="utf-8")
    pdf = HERE / "wiring-diagram.pdf"
    EDGE_PROFILE.mkdir(parents=True, exist_ok=True)
    subprocess.run([EDGE, "--headless=new", "--disable-gpu", "--no-pdf-header-footer", f"--user-data-dir={EDGE_PROFILE}",
                    f"--print-to-pdf={pdf}", out.as_uri()], check=True, timeout=120, capture_output=True)
    # page 1 on its own, for a quick look on the phone
    (HERE / "wiring_stage1.svg").write_text(
        f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1100 690" width="1100" height="690">'
        f'<style>{CSS}</style><rect width="1100" height="690" fill="#fff"/>{svg_body}</svg>', encoding="utf-8")
    first = HERE / "_page1.html"
    first.write_text(html[:html.index('<div class="page p2">')] + "</body></html>", encoding="utf-8")
    png = HERE / "wiring_stage1.png"
    png.unlink(missing_ok=True)
    subprocess.run([EDGE, "--headless=new", "--no-first-run", f"--user-data-dir={EDGE_PROFILE}", "--hide-scrollbars",
                    "--force-device-scale-factor=2", "--window-size=1123,794", "--virtual-time-budget=3000",
                    f"--screenshot={png}", first.as_uri()], check=True, timeout=120, capture_output=True)
    first.unlink()
    print("wrote", out.name, pdf.name, png.name)


if __name__ == "__main__":
    build()
