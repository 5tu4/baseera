"""Flat check views of the printed parts (SVG line drawings on one PNG).

Run after baseera_glasses.py:  python check_views.py
Writes out/renders/check_views.png
"""

import subprocess
import sys
from pathlib import Path

import cadquery as cq

sys.path.insert(0, str(Path(__file__).resolve().parent))
import baseera_glasses as g   # noqa: E402
from make_viewer import EDGE, EDGE_PROFILE   # noqa: E402

HERE = Path(__file__).resolve().parent
OUT = HERE / "out" / "renders"
TMP = HERE / "out" / "check"

VIEWS = [  # (title, part, where the camera is, show hidden lines)
    ("right housing, open side (lid off)", "temple_right", (1, 0, 0), False),
    ("right housing, inner wall (grille)", "temple_right", (-1, 0, 0), False),
    ("right housing, from above (XIAO USB-C + button)", "temple_right", (0, 0, 1), False),
    ("right housing, from the front (camera)", "temple_right", (0, 1, 0), False),
    ("left housing, open side (lid off)", "temple_left", (-1, 0, 0), False),
    ("left housing, from above (switch)", "temple_left", (0, 0, 1), False),
    ("left housing, from behind (charger USB-C)", "temple_left", (0, -1, 0), False),
    ("left housing, from below (floor sensor window)", "temple_left", (0, 0, -1), False),
    ("right lid, inside (XIAO stop, vibration module frame)", "lid_right", (-1, 0, 0), False),
    ("left lid, inside (charger and battery ribs)", "lid_left", (1, 0, 0), False),
    ("frame front, from the front", "frame_front", (0, 1, 0), False),
    ("frame front, from behind (lens rebate, groove)", "frame_front", (0, -1, 0), False),
]


def main():
    TMP.mkdir(parents=True, exist_ok=True)
    local, printed, clear, pads, elec = g.build()
    cells = []
    for i, (title, part, direction, hidden) in enumerate(VIEWS):
        svg = TMP / f"v{i}.svg"
        solid = local[part]
        if part.startswith("temple"):   # drop the temple bar so the housing fills the view
            solid = solid.intersect(g.box((-100, 100), (g.H_Y[0] - 1, g.H_Y[1] + 1), (-50, 50)))
        cq.exporters.export(solid, str(svg), opt={
            "width": 840, "height": 560, "marginLeft": 12, "marginTop": 12, "showAxes": False,
            "projectionDir": direction, "strokeWidth": 0.35, "strokeColor": (20, 20, 20),
            "hiddenColor": (170, 170, 170), "showHidden": hidden,
        })
        cells.append(f'<figure><figcaption>{title}</figcaption>{svg.read_text(encoding="utf-8")}</figure>')
    html = TMP / "check.html"
    html.write_text(
        "<!doctype html><meta charset=utf-8><style>body{margin:0;background:#fff;font:14px Arial}"
        ".g{display:grid;grid-template-columns:repeat(2,860px);gap:8px;padding:8px}"
        "figure{margin:0;border:1px solid #ccc}figcaption{padding:4px 8px;background:#eee}"
        "svg{display:block}</style><div class=g>" + "".join(cells) + "</div>",
        encoding="utf-8")
    png = OUT / "check_views.png"
    png.unlink(missing_ok=True)
    subprocess.run([
        str(EDGE), "--headless=new", "--use-angle=swiftshader", "--enable-unsafe-swiftshader",
        "--no-first-run", f"--user-data-dir={EDGE_PROFILE}", "--hide-scrollbars",
        "--window-size=1740,3600", "--virtual-time-budget=5000", f"--screenshot={png}", html.as_uri(),
    ], check=True, capture_output=True, timeout=300)
    print(png, png.stat().st_size // 1024, "KB")


if __name__ == "__main__":
    try:
        main()
    finally:
        import os
        sys.stdout.flush()
        os._exit(0 if sys.exc_info()[0] is None else 1)
