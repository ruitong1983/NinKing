"""
Card frame transparency script — makes center fill area transparent while
preserving border decorations.

Uses BFS flood fill from center point: only pixels whose color is within
threshold distance of the center color are made transparent.

Usage:
    python tools/make_frame_transparent.py [--threshold 35] [--dry-run]

Args:
    --threshold: Color distance threshold (0-255), default 35.
    --dry-run: Preview only, no file writes.
"""

import os
import math
import sys

PROJECT_ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
FRAME_DIR = os.path.join(PROJECT_ROOT, "assets", "images", "ninjas", "frames")
RARITIES = ["common", "uncommon", "rare", "legendary"]

DEFAULT_THRESHOLD = 35


def flood_fill_alpha(img, start_x, start_y, threshold):
    """BFS flood fill from (start_x, start_y). Pixels within color threshold
    get alpha=0."""
    w, h = img.size
    pixels = img.load()

    start_r, start_g, start_b, _ = pixels[start_x, start_y]

    visited = set()
    stack = [(start_x, start_y)]

    while stack:
        x, y = stack.pop()
        if (x, y) in visited:
            continue
        visited.add((x, y))

        r, g, b, a = pixels[x, y]
        dr = r - start_r
        dg = g - start_g
        db = b - start_b
        dist = math.sqrt(dr * dr + dg * dg + db * db)

        if dist < threshold:
            pixels[x, y] = (r, g, b, 0)  # Make transparent
            # Spread to 4-connected neighbors
            for nx, ny in ((x - 1, y), (x + 1, y), (x, y - 1), (x, y + 1)):
                if 0 <= nx < w and 0 <= ny < h and (nx, ny) not in visited:
                    stack.append((nx, ny))

    return img


def process_frame(filepath, threshold, dry_run):
    fname = os.path.basename(filepath)
    if not os.path.exists(filepath):
        print("  [SKIP] File not found:", filepath)
        return False

    from PIL import Image
    img = Image.open(filepath).convert("RGBA")
    w, h = img.size
    cx, cy = w // 2, h // 2

    pixels = img.load()
    center_color = pixels[cx, cy][:3]
    print("  Center RGB:", center_color, " Size:", w, "x", h)

    # Count opaque pixels before
    pre_opaque = sum(1 for y in range(h) for x in range(w) if pixels[x, y][3] > 0)

    # Flood fill
    flood_fill_alpha(img, cx, cy, threshold)

    # Count opaque pixels after
    post_opaque = sum(1 for y in range(h) for x in range(w) if pixels[x, y][3] > 0)
    removed = pre_opaque - post_opaque
    total = w * h
    print(f"  Threshold: {threshold} | Transparent: {removed} ({100*removed/total:.1f}%) | Retained opaque: {post_opaque}")

    if not dry_run:
        img.save(filepath)
        print("  [SAVED]", fname)
    else:
        print("  [PREVIEW] No write")

    return True


def main():
    threshold = DEFAULT_THRESHOLD
    dry_run = False
    for arg in sys.argv[1:]:
        if arg.startswith("--threshold="):
            threshold = int(arg.split("=")[1])
        elif arg == "--dry-run":
            dry_run = True
        elif arg == "--help":
            print(__doc__)
            return

    try:
        from PIL import Image
    except ImportError:
        print("Need Pillow: pip install Pillow")
        sys.exit(1)

    print(f"Frame transparency tool (threshold={threshold}, dry_run={dry_run})")
    print("=" * 50)

    success = 0
    for rarity in RARITIES:
        fname = f"ninja_frame_{rarity}.png"
        path = os.path.join(FRAME_DIR, fname)
        print(f"\n> {fname}")
        ok = process_frame(path, threshold, dry_run)
        if ok:
            success += 1

    print(f"\n{'=' * 50}")
    print(f"Done: {success}/{len(RARITIES)} files{' (preview)' if dry_run else ''}")
    if dry_run:
        print("Remove --dry-run to write changes.")
    else:
        print("Reimport in Godot editor (right-click -> Reimport) to refresh cache.")


if __name__ == "__main__":
    main()
