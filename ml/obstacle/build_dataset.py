"""Builds Baseera's obstacle dataset in YOLO format.

Sources (downloaded through FiftyOne, no accounts needed):
  * COCO 2017      people, vehicles, dogs, chairs, benches, tables, and
                   general obstacles (plant pots, sofas, hydrants...)
  * Open Images V7 doors, stairs, trees, street-light poles
  * your own labelled glasses-camera photos (--photos), which matter most:
    the glasses camera is low quality and wide-angle, unlike these photos.

    python build_dataset.py --out /content/obstacles
    python build_dataset.py --out /content/obstacles --photos /path/to/photos

--photos is a folder with images/ and labels/ (YOLO .txt files) labelled with
the classes in classes.txt, which this script writes next to the dataset.
Every 10th image (by file name) goes to validation.
"""

import argparse
import os
import shutil
import zlib
from collections import Counter
from pathlib import Path

from classes import (
    COCO,
    COCO_PER_CLASS,
    COCO_PER_CLASS_OVERRIDE,
    LABELS,
    OPEN_IMAGES_ALSO,
    OPEN_IMAGES_PER_CLASS,
    OPEN_IMAGES_TARGETS,
)

SEED = 51
IMAGE_TYPES = {".jpg", ".jpeg", ".png", ".bmp", ".webp"}


def split_of(name: str) -> str:
    return "val" if zlib.crc32(name.encode()) % 10 == 0 else "train"


class Writer:
    def __init__(self, out: Path):
        self.out = out
        self.names: set[str] = set()
        self.boxes = Counter()
        self.images = Counter()
        for split in ("train", "val"):
            (out / "images" / split).mkdir(parents=True, exist_ok=True)
            (out / "labels" / split).mkdir(parents=True, exist_ok=True)

    def add(self, image: str, name: str, lines: list[str]) -> None:
        """One image and its YOLO label lines (skipped if already added)."""
        if name in self.names or not lines:
            return
        self.names.add(name)
        split = split_of(name)
        target = self.out / "images" / split / name
        try:
            os.link(image, target)  # no copy when on the same disk
        except OSError:
            shutil.copy2(image, target)
        (self.out / "labels" / split / Path(name).with_suffix(".txt")).write_text(
            "\n".join(lines) + "\n"
        )
        self.images[split] += 1
        for line in lines:
            self.boxes[LABELS[int(line.split()[0])]] += 1

    def add_fiftyone(self, dataset, mapping: dict[str, str], prefix: str) -> None:
        for sample in dataset.iter_samples(progress=True):
            detections = sample["ground_truth"]
            lines = []
            for d in detections.detections if detections else []:
                label = mapping.get(d.label)
                if label is None:
                    continue
                x, y, w, h = d.bounding_box  # top-left x, y, w, h in 0..1
                lines.append(
                    f"{LABELS.index(label)} {x + w / 2:.6f} {y + h / 2:.6f} {w:.6f} {h:.6f}"
                )
            self.add(sample.filepath, f"{prefix}_{Path(sample.filepath).name}", lines)

    def write_yaml(self) -> Path:
        names = "\n".join(f"  {i}: {label}" for i, label in enumerate(LABELS))
        yaml = self.out / "dataset.yaml"
        yaml.write_text(
            f"path: {self.out.resolve().as_posix()}\n"
            "train: images/train\nval: images/val\n"
            f"names:\n{names}\n"
        )
        (self.out / "classes.txt").write_text("\n".join(LABELS) + "\n")
        return yaml


def add_coco(writer: Writer) -> None:
    import fiftyone.zoo as foz

    for source in COCO:
        dataset = foz.load_zoo_dataset(
            "coco-2017",
            split="train",
            label_types=["detections"],
            classes=[source],
            max_samples=COCO_PER_CLASS_OVERRIDE.get(source, COCO_PER_CLASS),
            shuffle=True,
            seed=SEED,
            label_field="ground_truth",
            dataset_name=f"baseera-coco-{source.replace(' ', '-')}",
            drop_existing_dataset=True,
        )
        writer.add_fiftyone(dataset, COCO, "coco")
        dataset.delete()


def add_open_images(writer: Writer) -> None:
    import fiftyone.utils.openimages as fouo
    import fiftyone.zoo as foz

    available = set(fouo.get_classes(version="v7"))
    missing = [c for c in {**OPEN_IMAGES_TARGETS, **OPEN_IMAGES_ALSO} if c not in available]
    if missing:
        print(f"Not in Open Images V7, skipped: {missing}")
    mapping = {
        k: v for k, v in {**OPEN_IMAGES_ALSO, **OPEN_IMAGES_TARGETS}.items() if k in available
    }
    for source, count in OPEN_IMAGES_PER_CLASS.items():
        if source not in available:
            continue
        dataset = foz.load_zoo_dataset(
            "open-images-v7",
            split="train",
            label_types=["detections"],
            classes=[source],
            max_samples=count,
            shuffle=True,
            seed=SEED,
            label_field="ground_truth",
            dataset_name=f"baseera-oi-{source.replace(' ', '-')}",
            drop_existing_dataset=True,
        )
        writer.add_fiftyone(dataset, mapping, "oi")
        dataset.delete()


def add_photos(writer: Writer, folder: Path) -> None:
    """Your own photos, already in YOLO format with our class order."""
    for image in sorted((folder / "images").rglob("*")):
        if image.suffix.lower() not in IMAGE_TYPES:
            continue
        label = folder / "labels" / image.relative_to(folder / "images").with_suffix(".txt")
        lines = label.read_text().split("\n") if label.exists() else []
        lines = [l.strip() for l in lines if l.strip()]
        bad = [l for l in lines if not 0 <= int(l.split()[0]) < len(LABELS)]
        if bad:
            raise SystemExit(f"{label}: class id outside classes.txt: {bad[0]}")
        writer.add(str(image), f"own_{image.name}", lines)


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    parser.add_argument("--out", type=Path, required=True)
    parser.add_argument("--photos", type=Path, help="your labelled glasses photos")
    parser.add_argument("--skip-public", action="store_true", help="only --photos")
    args = parser.parse_args()

    writer = Writer(args.out)
    if not args.skip_public:
        add_coco(writer)
        add_open_images(writer)
    if args.photos:
        add_photos(writer, args.photos)
    yaml = writer.write_yaml()

    print(f"\nWrote {yaml}")
    print(f"images: {dict(writer.images)}")
    for label in LABELS:
        print(f"  {label:<10} {writer.boxes[label]:>6} boxes")


if __name__ == "__main__":
    main()
