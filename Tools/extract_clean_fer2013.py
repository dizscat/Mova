#!/usr/bin/env python3
"""
Extract and clean FER2013 image-folder zip for quick ML use.

Input zip layout expected:
  train/<label>/*.jpg
  test/<label>/*.jpg

Output layout:
  <output>/
    train/<label>/*.jpg
    test/<label>/*.jpg

Optional anomaly quarantine:
  <output>_anomalies/
    train/<label>/*.jpg
    test/<label>/*.jpg

The script removes clearly problematic files:
  - unreadable images
  - images with unexpected dimensions
  - tiny files below a byte threshold
  - uniform images (all pixels identical)
"""

from __future__ import annotations

import argparse
import io
import json
import shutil
import sys
import zipfile
from collections import Counter, defaultdict
from pathlib import Path

from PIL import Image, UnidentifiedImageError


VALID_SPLITS = {"train", "test"}
VALID_LABELS = {"angry", "disgust", "fear", "happy", "neutral", "sad", "surprise"}


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--zip",
        required=True,
        help="Path to FER2013 image-folder zip.",
    )
    parser.add_argument(
        "--output",
        default="MLTrainingData/FER2013_Cleaned",
        help="Directory for cleaned extracted dataset.",
    )
    parser.add_argument(
        "--quarantine-output",
        default="",
        help="Optional directory for extracted anomalies. Defaults to <output>_anomalies.",
    )
    parser.add_argument(
        "--min-bytes",
        type=int,
        default=1000,
        help="Minimum compressed file size in bytes before a file is treated as anomalous.",
    )
    parser.add_argument(
        "--expected-width",
        type=int,
        default=48,
        help="Expected image width.",
    )
    parser.add_argument(
        "--expected-height",
        type=int,
        default=48,
        help="Expected image height.",
    )
    parser.add_argument(
        "--keep-anomalies",
        action="store_true",
        help="Extract anomalous files into a quarantine folder for manual review.",
    )
    parser.add_argument(
        "--keep-existing",
        action="store_true",
        help="Do not delete output folders before writing.",
    )
    return parser.parse_args()


def reset_dir(path: Path, keep_existing: bool) -> None:
    if path.exists() and not keep_existing:
        shutil.rmtree(path)
    path.mkdir(parents=True, exist_ok=True)


def is_dataset_member(name: str) -> bool:
    parts = name.split("/")
    if len(parts) != 3:
        return False
    split, label, filename = parts
    if split not in VALID_SPLITS or label not in VALID_LABELS:
        return False
    return filename.lower().endswith((".jpg", ".jpeg", ".png"))


def analyze_image(
    data: bytes,
    expected_size: tuple[int, int],
    min_bytes: int,
) -> list[str]:
    reasons: list[str] = []
    if len(data) < min_bytes:
        reasons.append(f"small_file_lt_{min_bytes}")

    try:
        with Image.open(io.BytesIO(data)) as image:
            image.load()
            if image.size != expected_size:
                reasons.append(f"unexpected_size_{image.size[0]}x{image.size[1]}")

            grayscale = image.convert("L")
            low, high = grayscale.getextrema()
            if low == high:
                reasons.append("uniform_pixels")
    except (UnidentifiedImageError, OSError):
        reasons.append("unreadable_image")

    return reasons


def extract_bytes(data: bytes, destination: Path) -> None:
    destination.parent.mkdir(parents=True, exist_ok=True)
    destination.write_bytes(data)


def build_summary(
    source_zip: Path,
    output: Path,
    quarantine_output: Path | None,
    min_bytes: int,
    expected_size: tuple[int, int],
) -> dict[str, object]:
    return {
        "source_zip": str(source_zip),
        "output": str(output.resolve()),
        "quarantine_output": str(quarantine_output.resolve()) if quarantine_output else None,
        "rules": {
            "min_bytes": min_bytes,
            "expected_size": {"width": expected_size[0], "height": expected_size[1]},
            "drop_uniform_images": True,
        },
        "counts": {
            "total_seen": 0,
            "clean_kept": 0,
            "anomalies_skipped": 0,
        },
        "clean_counts": {"train": {}, "test": {}},
        "anomaly_counts": {"train": {}, "test": {}},
        "anomaly_reasons": {},
        "anomaly_examples": [],
    }


def clean_dataset(args: argparse.Namespace) -> dict[str, object]:
    zip_path = Path(args.zip)
    output = Path(args.output)
    quarantine_output = (
        Path(args.quarantine_output)
        if args.quarantine_output
        else Path(f"{args.output}_anomalies")
    )
    expected_size = (args.expected_width, args.expected_height)

    if not zip_path.exists():
        raise FileNotFoundError(f"Zip not found: {zip_path}")

    reset_dir(output, args.keep_existing)
    if args.keep_anomalies:
        reset_dir(quarantine_output, args.keep_existing)

    clean_counts: dict[str, Counter[str]] = {
        "train": Counter(),
        "test": Counter(),
    }
    anomaly_counts: dict[str, Counter[str]] = {
        "train": Counter(),
        "test": Counter(),
    }
    anomaly_reasons = Counter()
    anomaly_examples: list[dict[str, object]] = []

    summary = build_summary(
        source_zip=zip_path,
        output=output,
        quarantine_output=quarantine_output if args.keep_anomalies else None,
        min_bytes=args.min_bytes,
        expected_size=expected_size,
    )

    with zipfile.ZipFile(zip_path) as archive:
        for member in archive.infolist():
            name = member.filename
            if not is_dataset_member(name):
                continue

            split, label, filename = name.split("/")
            data = archive.read(member)
            reasons = analyze_image(data, expected_size=expected_size, min_bytes=args.min_bytes)

            summary["counts"]["total_seen"] += 1
            destination = output / split / label / filename

            if reasons:
                summary["counts"]["anomalies_skipped"] += 1
                anomaly_counts[split][label] += 1
                for reason in reasons:
                    anomaly_reasons[reason] += 1

                if len(anomaly_examples) < 50:
                    anomaly_examples.append(
                        {
                            "member": name,
                            "compressed_bytes": len(data),
                            "reasons": reasons,
                        }
                    )

                if args.keep_anomalies:
                    extract_bytes(data, quarantine_output / split / label / filename)
                continue

            extract_bytes(data, destination)
            summary["counts"]["clean_kept"] += 1
            clean_counts[split][label] += 1

    for split in ("train", "test"):
        for label in sorted(VALID_LABELS):
            summary["clean_counts"][split][label] = clean_counts[split][label]
            summary["anomaly_counts"][split][label] = anomaly_counts[split][label]

    summary["anomaly_reasons"] = dict(sorted(anomaly_reasons.items()))
    summary["anomaly_examples"] = anomaly_examples

    summary_path = output / "cleaning_summary.json"
    summary_path.write_text(json.dumps(summary, indent=2), encoding="utf-8")

    readme = output / "README.md"
    readme.write_text(
        """# FER2013 Cleaned Dataset

This folder is generated by `Tools/extract_clean_fer2013.py`.

Cleaning rules:

- keep only valid `train/<label>/file` and `test/<label>/file` members
- remove unreadable images
- remove images that are not 48x48
- remove files smaller than the configured byte threshold
- remove uniform images where all pixels are identical

See `cleaning_summary.json` for exact counts and examples.
""",
        encoding="utf-8",
    )

    if args.keep_anomalies:
        quarantine_summary = quarantine_output / "README.md"
        quarantine_summary.write_text(
            """# FER2013 Quarantine

This folder contains files skipped by `Tools/extract_clean_fer2013.py`
for manual inspection.
""",
            encoding="utf-8",
        )

    return summary


def main() -> int:
    args = parse_args()
    try:
        summary = clean_dataset(args)
    except Exception as error:
        print(f"ERROR: {error}", file=sys.stderr)
        return 1

    print(json.dumps(summary["counts"], indent=2))
    print(f"\nClean dataset: {summary['output']}")
    if summary["quarantine_output"]:
        print(f"Anomalies: {summary['quarantine_output']}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
