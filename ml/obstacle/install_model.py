"""Copies a model exported by train_obstacles.ipynb into the app.

    python install_model.py path/to/export

The folder must hold obstacles.tflite and obstacle_labels.txt (the notebook
writes both to Drive: MyDrive/baseera/export). Rebuild the app afterwards.
"""

import re
import shutil
import sys
from pathlib import Path

HERE = Path(__file__).resolve().parent
APP = HERE.parent.parent / "app"
OBSTACLES_DART = APP / "lib" / "data" / "obstacles.dart"


def app_labels() -> set[str]:
    """Labels the app understands: ObstacleKind names plus COCO aliases."""
    dart = OBSTACLES_DART.read_text(encoding="utf-8")
    kinds = set(re.findall(r"^  (\w+)\(\d+, '", dart, flags=re.M))
    aliases = set(re.findall(r"^  '([^']+)': ObstacleKind\.", dart, flags=re.M))
    return kinds | aliases


def main() -> None:
    if len(sys.argv) != 2:
        raise SystemExit(__doc__)
    source = Path(sys.argv[1])
    model, labels = source / "obstacles.tflite", source / "obstacle_labels.txt"
    for f in (model, labels):
        if not f.exists():
            raise SystemExit(f"missing {f}")

    names = [l.strip() for l in labels.read_text(encoding="utf-8").splitlines() if l.strip()]
    known = app_labels()
    unknown = [n for n in names if n.lower() not in known]
    print(f"{len(names)} labels; the app warns about {len(names) - len(unknown)}")
    if unknown:
        print(f"  ignored by the app: {', '.join(unknown)}")

    target = APP / "assets" / "model"
    shutil.copy2(model, target / "obstacles.tflite")
    shutil.copy2(labels, target / "obstacle_labels.txt")
    print(f"Installed into {target} — rebuild the app (flutter run / build apk).")


if __name__ == "__main__":
    main()
