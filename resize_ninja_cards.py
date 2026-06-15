#!/usr/bin/env python3
"""Resize all ninja card images to 500×700 in place."""
import os
import sys
from PIL import Image

NINJAS_DIR = r"E:\01 Code\Godot_v4.6.2\NinKing\assets\images\cards\ninjas"
TARGET = (500, 700)

# Files that need no change (already 500×700)
skip = {"n_001.png", "n_002.png", "n_003.png", "n_004.png", "n_006.png"}

resized = []
errors = []
skipped = []

for fname in sorted(os.listdir(NINJAS_DIR)):
    if not fname.lower().endswith(".png") or fname.endswith(".import"):
        continue

    fpath = os.path.join(NINJAS_DIR, fname)
    img = Image.open(fpath)
    w, h = img.size

    if (w, h) == TARGET:
        skipped.append(f"{fname} (already {w}x{h})")
        continue

    if fname in skip:
        # Already 500×700 but double-check
        skipped.append(f"{fname} (in skip list)")
        continue

    # Resize with Lanczos for best quality
    img_resized = img.resize(TARGET, Image.LANCZOS)
    img_resized.save(fpath, "PNG")
    resized.append(f"{fname}: {w}x{h} → 500×700")

print("=== Skipped (already 500×700) ===")
for s in skipped:
    print(f"  {s}")

print(f"\n=== Resized ({len(resized)} files) ===")
for r in resized:
    print(f"  {r}")

if errors:
    print(f"\n=== Errors ({len(errors)}) ===")
    for e in errors:
        print(f"  {e}")

print(f"\nDone. {len(resized)} resized, {len(skipped)} skipped, {len(errors)} errors.")
sys.exit(0 if not errors else 1)
