#!/usr/bin/env python3
"""
Prepare FER2013 image-folder dataset for Mova.

Input zip layout expected:
  train/<label>/*.jpg
  test/<label>/*.jpg

Output layout for Create ML:
  MLTrainingData/FER2013_MovaBalanced/
    train/<mova_label>/*.jpg
    validation/<mova_label>/*.jpg
    test/<mova_label>/*.jpg

The script:
  - renames labels to match Mova's EmotionType naming
  - creates a validation split from the original train split
  - balances train classes to a target count
  - augments minority classes with macOS `sips` when needed
"""

from __future__ import annotations

import argparse
import contextlib
import json
import random
import shutil
import subprocess
import sys
import tempfile
import zipfile
from collections import defaultdict
from pathlib import Path

from PIL import Image


LABEL_MAP = {
    "angry": "angry",
    "disgust": "disgusted",
    "fear": "fearful",
    "happy": "happy",
    "neutral": "neutral",
    "sad": "sad",
    "surprise": "surprised",
}

MOVA_LABELS = [
    "angry",
    "disgusted",
    "fearful",
    "happy",
    "neutral",
    "sad",
    "surprised",
]

AUGMENTATIONS = [
    ("flip", ["-f", "horizontal"]),
    ("rot-8", ["-r", "-8"]),
    ("rot8", ["-r", "8"]),
    ("rot-5", ["-r", "-5"]),
    ("rot5", ["-r", "5"]),
    ("flip-rot-8", ["-f", "horizontal", "-r", "-8"]),
    ("flip-rot8", ["-f", "horizontal", "-r", "8"]),
    ("rot-10", ["-r", "-10"]),
    ("rot10", ["-r", "10"]),
    ("flip-rot5", ["-f", "horizontal", "-r", "5"]),
    ("flip-rot-5", ["-f", "horizontal", "-r", "-5"]),
]


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--input",
        default="/Users/a18/Downloads/archive (1).zip",
        help="Path to FER2013 image-folder zip or extracted folder.",
    )
    parser.add_argument(
        "--output",
        default="MLTrainingData/FER2013_MovaBalanced",
        help="Output dataset directory.",
    )
    parser.add_argument(
        "--target-train-per-class",
        type=int,
        default=4000,
        help="Balanced train count per class after augmentation/downsampling.",
    )
    parser.add_argument(
        "--validation-ratio",
        type=float,
        default=0.15,
        help="Validation ratio carved from original train split.",
    )
    parser.add_argument(
        "--max-validation-per-class",
        type=int,
        default=0,
        help="Optional cap for validation images per class. 0 means no cap.",
    )
    parser.add_argument(
        "--max-test-per-class",
        type=int,
        default=0,
        help="Optional cap for test images per class. 0 means no cap.",
    )
    parser.add_argument(
        "--seed",
        type=int,
        default=2506,
        help="Random seed for repeatable splits.",
    )
    parser.add_argument(
        "--keep-existing",
        action="store_true",
        help="Do not delete output directory before writing.",
    )
    parser.add_argument(
        "--temp-dir",
        default="",
        help="Optional temp directory for augmentation work files.",
    )
    return parser.parse_args()


def collect_images(source_path: Path) -> dict[str, dict[str, list[str]]]:
    images: dict[str, dict[str, list[str]]] = {
        "train": defaultdict(list),
        "test": defaultdict(list),
    }

    if source_path.is_dir():
        for path in source_path.rglob("*"):
            if not path.is_file():
                continue
            relative = path.relative_to(source_path).as_posix()
            parts = relative.split("/")
            if len(parts) != 3:
                continue
            split, raw_label, filename = parts
            if split not in images or raw_label not in LABEL_MAP:
                continue
            if not filename.lower().endswith((".jpg", ".jpeg", ".png")):
                continue
            images[split][LABEL_MAP[raw_label]].append(relative)
        return images

    with zipfile.ZipFile(source_path) as archive:
        for name in archive.namelist():
            parts = name.split("/")
            if len(parts) != 3:
                continue
            split, raw_label, filename = parts
            if split not in images or raw_label not in LABEL_MAP:
                continue
            if not filename.lower().endswith((".jpg", ".jpeg", ".png")):
                continue
            images[split][LABEL_MAP[raw_label]].append(name)

    return images


def reset_output(output: Path, keep_existing: bool) -> None:
    if output.exists() and not keep_existing:
        shutil.rmtree(output)
    for split in ("train", "validation", "test"):
        for label in MOVA_LABELS:
            (output / split / label).mkdir(parents=True, exist_ok=True)


def safe_name(prefix: str, archive_name: str) -> str:
    stem = Path(archive_name).stem
    suffix = Path(archive_name).suffix.lower() or ".jpg"
    return f"{prefix}_{stem}{suffix}"


def extract_member(source_root: Path | None, archive: zipfile.ZipFile | None, member: str, destination: Path) -> None:
    destination.parent.mkdir(parents=True, exist_ok=True)
    if source_root is not None:
        shutil.copy2(source_root / Path(member), destination)
        return

    if archive is None:
        raise RuntimeError("Archive source missing for zip extraction.")

    with archive.open(member) as source, destination.open("wb") as target:
        shutil.copyfileobj(source, target)


def augment_with_pillow(source: Path, destination: Path, args: list[str]) -> bool:
    try:
        with Image.open(source) as image:
            transformed = image.copy()
            if len(args) >= 2 and args[0] == "-f" and args[1] == "horizontal":
                transformed = transformed.transpose(Image.Transpose.FLIP_LEFT_RIGHT)
            if "-r" in args:
                index = args.index("-r")
                angle = float(args[index + 1])
                transformed = transformed.rotate(angle, resample=Image.Resampling.BILINEAR)
            destination.parent.mkdir(parents=True, exist_ok=True)
            transformed.save(destination)
        return destination.exists()
    except Exception:
        return False


def augment_with_sips(source: Path, destination: Path, args: list[str]) -> bool:
    command = ["sips", *args, str(source), "-o", str(destination)]
    try:
        result = subprocess.run(
            command,
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
            check=False,
        )
    except FileNotFoundError:
        return False
    return result.returncode == 0 and destination.exists()


def duplicate_as_fallback(source: Path, destination: Path) -> None:
    shutil.copy2(source, destination)


def prepare_dataset(args: argparse.Namespace) -> dict[str, object]:
    random.seed(args.seed)

    source_path = Path(args.input)
    output = Path(args.output)
    if not source_path.exists():
        raise FileNotFoundError(f"Input not found: {source_path}")

    reset_output(output, args.keep_existing)
    images = collect_images(source_path)

    summary: dict[str, object] = {
        "source_input": str(source_path),
        "output": str(output.resolve()),
        "temp_dir": str(Path(args.temp_dir).resolve()) if args.temp_dir else None,
        "target_train_per_class": args.target_train_per_class,
        "validation_ratio": args.validation_ratio,
        "max_validation_per_class": args.max_validation_per_class,
        "max_test_per_class": args.max_test_per_class,
        "seed": args.seed,
        "counts": {
            "train": {},
            "validation": {},
            "test": {},
        },
        "notes": [
            "Train split is balanced by downsampling large classes and augmenting minority classes.",
            "Validation and test splits are not augmented.",
            "Labels are renamed to match Mova EmotionType values.",
        ],
    }

    archive_cm = zipfile.ZipFile(source_path) if source_path.is_file() else contextlib.nullcontext(None)
    temp_root = Path(args.temp_dir) if args.temp_dir else Path(tempfile.gettempdir())
    temp_root.mkdir(parents=True, exist_ok=True)
    tmpdir = temp_root / "prepare_fer2013_work"
    if tmpdir.exists():
        shutil.rmtree(tmpdir, ignore_errors=True)
    tmpdir.mkdir(parents=True, exist_ok=True)

    with archive_cm as archive:
        source_root = source_path if source_path.is_dir() else None

        for label in MOVA_LABELS:
            members = list(images["train"][label])
            random.shuffle(members)

            validation_count = max(1, int(len(members) * args.validation_ratio))
            if args.max_validation_per_class > 0:
                validation_count = min(validation_count, args.max_validation_per_class)
            validation_members = members[:validation_count]
            train_pool = members[validation_count:]

            for member in validation_members:
                destination = output / "validation" / label / safe_name("val", member)
                extract_member(source_root, archive, member, destination)

            if len(train_pool) >= args.target_train_per_class:
                selected_train = random.sample(train_pool, args.target_train_per_class)
            else:
                selected_train = train_pool

            original_train_files: list[Path] = []
            for member in selected_train:
                destination = output / "train" / label / safe_name("orig", member)
                extract_member(source_root, archive, member, destination)
                original_train_files.append(destination)

            needed = args.target_train_per_class - len(original_train_files)
            if needed > 0:
                if not original_train_files:
                    raise RuntimeError(f"No train images available for label: {label}")

                for index in range(needed):
                    source = original_train_files[index % len(original_train_files)]
                    aug_name, aug_args = AUGMENTATIONS[index % len(AUGMENTATIONS)]
                    destination = (
                        output
                        / "train"
                        / label
                        / f"aug_{index:05d}_{aug_name}_{source.stem}.jpg"
                    )

                    # Use a temp copy so sips never mutates the selected original.
                    temp_source = tmpdir / f"{label}_{index}_{source.name}"
                    shutil.copy2(source, temp_source)
                    if not augment_with_sips(temp_source, destination, aug_args) and not augment_with_pillow(
                        temp_source,
                        destination,
                        aug_args,
                    ):
                        duplicate_as_fallback(source, destination)

            test_members = list(images["test"][label])
            random.shuffle(test_members)
            if args.max_test_per_class > 0:
                test_members = test_members[:args.max_test_per_class]

            for member in test_members:
                destination = output / "test" / label / safe_name("test", member)
                extract_member(source_root, archive, member, destination)

    shutil.rmtree(tmpdir, ignore_errors=True)

    for split in ("train", "validation", "test"):
        for label in MOVA_LABELS:
            count = len(list((output / split / label).glob("*")))
            summary["counts"][split][label] = count

    summary_path = output / "dataset_summary.json"
    summary_path.write_text(json.dumps(summary, indent=2), encoding="utf-8")

    readme = output / "README.md"
    readme.write_text(
        """# FER2013 Mova Balanced Dataset

This folder is generated by `Tools/prepare_fer2013_for_mova.py`.

Use in Create ML:

1. Open Create ML.
2. Choose Image Classification.
3. Use `train/` for Training Data.
4. Use `validation/` for Validation Data.
5. Use `test/` for Testing Data.
6. Export as `EmotionClassifierModel.mlmodel`.
7. Add it to `Mova/ML/` in Xcode.

Important:

- Training classes are balanced by downsampling and augmentation.
- Validation/test are kept natural for more honest evaluation.
- The `disgusted` class is still the riskiest because the source dataset has very few real examples.
""",
        encoding="utf-8",
    )

    return summary


def main() -> int:
    args = parse_args()
    try:
        summary = prepare_dataset(args)
    except Exception as error:
        print(f"ERROR: {error}", file=sys.stderr)
        return 1

    print(json.dumps(summary["counts"], indent=2))
    print(f"\nPrepared dataset: {summary['output']}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
