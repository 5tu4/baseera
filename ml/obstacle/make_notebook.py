"""Writes train_obstacles.ipynb with classes.py and build_dataset.py embedded,
so the notebook is one file to upload to Colab and never drifts from the
scripts. Run after editing either script:  python make_notebook.py
"""

import json
from pathlib import Path

HERE = Path(__file__).resolve().parent


def md(text: str) -> dict:
    return {"cell_type": "markdown", "metadata": {}, "source": text.strip("\n").splitlines(True)}


def code(text: str) -> dict:
    return {
        "cell_type": "code",
        "metadata": {},
        "execution_count": None,
        "outputs": [],
        "source": text.strip("\n").splitlines(True),
    }


def embed(name: str) -> dict:
    return code(f"%%writefile {name}\n" + (HERE / name).read_text(encoding="utf-8"))


CELLS = [
    md("""
# Baseera — obstacle model (YOLO11n)

Trains the model the app runs on frames from the glasses camera.

**Before you start:** Runtime → Change runtime type → **T4 GPU**.

Everything worth keeping goes to Google Drive (`MyDrive/baseera`): the
dataset (zipped once, so later sessions skip the download), training
checkpoints (a disconnected session resumes where it stopped) and the
exported model. Run the cells top to bottom; after a disconnect, run them
again — finished steps are skipped.
"""),
    code("""
from google.colab import drive
drive.mount('/content/drive')

import os
BASE = '/content/drive/MyDrive/baseera'
DATA = '/content/obstacles'
RUN = f'{BASE}/runs/obstacles'
EXPORT = f'{BASE}/export'
PHOTOS = f'{BASE}/glasses_photos'   # optional: your labelled glasses photos
for d in (BASE, EXPORT):
    os.makedirs(d, exist_ok=True)
"""),
    code("""
!pip -q install ultralytics fiftyone
"""),
    md("The two scripts from `ml/obstacle` in the Baseera project (kept in sync by `make_notebook.py`)."),
    embed("classes.py"),
    embed("build_dataset.py"),
    md("""
## 1. Quick start (optional): stock COCO model

Exports the off-the-shelf YOLO11n (people, vehicles, chairs, tables…) so the
app can be tested with real glasses before training finishes: install it from
`MyDrive/baseera/export/coco`. Doors, stairs, poles and trees only come with
the trained model.
"""),
    code("""
from ultralytics import YOLO
import glob, shutil

coco = YOLO('yolo11n.pt')
# format='saved_model' writes the TFLite files the app reads (NHWC input).
# Don't use format='tflite': Ultralytics >= 8.4.83 turns it into a LiteRT
# export with a different file name and layout.
coco.export(format='saved_model', imgsz=320)
f16 = glob.glob('yolo11n_saved_model/*float16.tflite')[0]
os.makedirs(f'{EXPORT}/coco', exist_ok=True)
shutil.copy(f16, f'{EXPORT}/coco/obstacles.tflite')
with open(f'{EXPORT}/coco/obstacle_labels.txt', 'w') as f:
    f.write('\\n'.join(coco.names[i] for i in range(len(coco.names))))
print('Saved to', f'{EXPORT}/coco')
"""),
    md("""
## 2. Dataset

About 24k photos from COCO and Open Images (first run: ~40–50 min, mostly
downloading). Your own glasses photos are added from `MyDrive/baseera/glasses_photos`
if that folder exists (YOLO format, classes in the order of `classes.txt`).
"""),
    code("""
ZIP = f'{BASE}/obstacles_dataset.zip'
if os.path.exists(f'{DATA}/dataset.yaml'):
    print('Dataset already here.')
elif os.path.exists(ZIP):
    !unzip -q -o "{ZIP}" -d /content
else:
    photos = f'--photos "{PHOTOS}"' if os.path.isdir(PHOTOS) else ''
    !python build_dataset.py --out {DATA} {photos}
    !cd /content && zip -q -r "{ZIP}" obstacles
print(open(f'{DATA}/dataset.yaml').read())
"""),
    md("""
## 3. Train

320×320 input, matching the glasses' 320×240 frames. ~2–3 min per epoch on a
T4. Checkpoints go to Drive; if the session drops, rerun from the top and
this cell resumes.
"""),
    code("""
from ultralytics import YOLO

last = f'{RUN}/weights/last.pt'
if os.path.exists(last):
    YOLO(last).train(resume=True)
else:
    YOLO('yolo11n.pt').train(
        data=f'{DATA}/dataset.yaml',
        imgsz=320,
        epochs=80,
        batch=64,
        patience=20,
        cos_lr=True,
        close_mosaic=10,
        project=f'{BASE}/runs',
        name='obstacles',
        exist_ok=True,
        workers=4,
    )
"""),
    md("## 4. How good is it?\n\nmAP50 per class on the validation photos (higher is better; above ~0.6 is solid for this use)."),
    code("""
best = YOLO(f'{RUN}/weights/best.pt')
metrics = best.val(data=f'{DATA}/dataset.yaml', imgsz=320)
for i, name in best.names.items():
    print(f'{name:<10} mAP50 {metrics.box.ap50[i]:.2f}')
print(f'all        mAP50 {metrics.box.map50:.2f}')
"""),
    md("## 5. Export for the app\n\nThen download `MyDrive/baseera/export` and run `python ml/obstacle/install_model.py <that folder>`."),
    code("""
import glob, shutil

best = YOLO(f'{RUN}/weights/best.pt')
best.export(format='saved_model', imgsz=320)  # see step 1 about 'tflite'
f16 = glob.glob(f'{RUN}/weights/best_saved_model/*float16.tflite')[0]
shutil.copy(f16, f'{EXPORT}/obstacles.tflite')
with open(f'{EXPORT}/obstacle_labels.txt', 'w') as f:
    f.write('\\n'.join(best.names[i] for i in range(len(best.names))))
print('Saved to', EXPORT, os.listdir(EXPORT))
"""),
    md("## 6. Look at a few predictions"),
    code("""
import random
from IPython.display import Image, display

images = glob.glob(f'{DATA}/images/val/*')
for result in best.predict(random.sample(images, 6), imgsz=320, conf=0.45, verbose=False):
    path = f'/content/pred_{os.path.basename(result.path)}.jpg'
    result.save(filename=path)
    display(Image(path, width=480))
"""),
]


def main() -> None:
    notebook = {
        "nbformat": 4,
        "nbformat_minor": 5,
        "metadata": {
            "accelerator": "GPU",
            "colab": {"provenance": [], "gpuType": "T4"},
            "kernelspec": {"name": "python3", "display_name": "Python 3"},
            "language_info": {"name": "python"},
        },
        "cells": CELLS,
    }
    out = HERE / "train_obstacles.ipynb"
    out.write_text(json.dumps(notebook, ensure_ascii=False, indent=1) + "\n", encoding="utf-8")
    print(f"wrote {out.name} ({len(CELLS)} cells)")


if __name__ == "__main__":
    main()
