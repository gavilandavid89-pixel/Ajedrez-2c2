#!/usr/bin/env python3
"""Static package audit for Ajedrez 2c2.

Finds missing res:// references across project source/resources and reports files
that should never be shipped (.godot, transient logs, local caches).
"""
from __future__ import annotations

import argparse
import re
from pathlib import Path

REF_RE = re.compile(r"res://[^\s\"'<>\)\],}`]+")
TEXT_EXTS = {".gd", ".tscn", ".tres", ".cfg", ".json", ".md"}
ALLOWED_GENERATED = {
    "bot_calibration_results.json",
}
TRANSIENT_SUFFIXES = {".log", ".tmp"}


def audit(root: Path) -> tuple[list[str], list[str], int]:
    refs: set[str] = set()
    transient: list[str] = []
    text_files = 0
    for path in root.rglob("*"):
        if not path.is_file():
            continue
        if ".godot" in path.parts:
            continue
        if path.suffix in TRANSIENT_SUFFIXES:
            transient.append(str(path.relative_to(root)))
        if path.suffix.lower() not in TEXT_EXTS:
            continue
        text_files += 1
        try:
            text = path.read_text(encoding="utf-8", errors="ignore")
        except OSError:
            continue
        refs.update(REF_RE.findall(text))

    missing: list[str] = []
    for ref in sorted(refs):
        rel = ref[6:]
        if Path(rel).name in ALLOWED_GENERATED:
            continue
        if not (root / rel).exists():
            missing.append(ref)
    return missing, transient, text_files


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("root", nargs="?", default=".")
    args = parser.parse_args()
    root = Path(args.root).resolve()
    missing, transient, text_files = audit(root)
    print(f"PACKAGE ROOT: {root}")
    print(f"TEXT FILES SCANNED: {text_files}")
    print(f"MISSING res:// REFERENCES: {len(missing)}")
    for item in missing:
        print(f"  MISSING {item}")
    print(f"TRANSIENT LOG/TMP FILES PRESENT: {len(transient)}")
    for item in transient[:50]:
        print(f"  TRANSIENT {item}")
    return 1 if missing else 0


if __name__ == "__main__":
    raise SystemExit(main())
