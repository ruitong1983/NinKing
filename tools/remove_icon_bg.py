"""Remove background from ninja icons while preserving manga outlines.

Strategy:
  1. Identify "color" pixels (saturated / mid-tone — not BG white or BG black)
  2. Dilate the color mask by a few px to include black outlines
  3. Everything outside the dilated mask → transparent
"""
import os
import numpy as np
from PIL import Image

ICON_DIR = r"E:\Code\Godot_v4.6.2-stable_win64\NinKing\assets\images\ninjas\icons"
WHITE_THRESHOLD = 220  # all channels above → white BG
DARK_THRESHOLD = 35    # all channels below → dark BG
DILATE_RADIUS = 4      # px to expand around color pixels (captures outlines)


def remove_bg(input_path: str, output_path: str) -> int:
    img = Image.open(input_path).convert("RGBA")
    arr = np.array(img, dtype=np.uint8)
    r, g, b, a = arr[:, :, 0], arr[:, :, 1], arr[:, :, 2], arr[:, :, 3]

    # Color mask: pixels that are NEITHER white-BG NOR dark-BG
    is_white = (r > WHITE_THRESHOLD) & (g > WHITE_THRESHOLD) & (b > WHITE_THRESHOLD)
    is_dark = (r < DARK_THRESHOLD) & (g < DARK_THRESHOLD) & (b < DARK_THRESHOLD)
    is_color = ~(is_white | is_dark)

    # Dilate color mask to include outline pixels
    # Use a distance transform or simple box dilate
    from scipy.ndimage import binary_dilation
    structure = np.ones((DILATE_RADIUS * 2 + 1, DILATE_RADIUS * 2 + 1), dtype=bool)
    dilated = binary_dilation(is_color, structure=structure, iterations=1)

    # Also keep pure black pixels that are very close to color (tight outlines)
    # Already covered by dilate

    # Set alpha: 255 where dilated mask is True, 0 elsewhere
    new_a = np.where(dilated, 255, 0).astype(np.uint8)
    arr[:, :, 3] = new_a

    result = Image.fromarray(arr, "RGBA")
    result.save(output_path, "PNG")
    return int(np.sum(new_a == 0))


if __name__ == "__main__":
    for f in sorted(os.listdir(ICON_DIR)):
        if not f.endswith(".png") or ".import" in f:
            continue
        path = os.path.join(ICON_DIR, f)
        deleted = remove_bg(path, path)
        pct = deleted * 100.0 / (2048 * 2048)
        print(f"  {f}: {deleted} px transparent ({pct:.1f}%)")
    print("Done")
