#!/usr/bin/env python3
"""
make_proxy.py
Converts a PNG image to an Autodesk Flame .p proxy icon.

Usage:
    python3 make_proxy.py <input.png>
    python3 make_proxy.py *.png

Notes:
    - Image width must be divisible by 4
    - Recommended size: 268x194
    - Output is written alongside the input as <name>.glsl.p
      (strip the .png extension and append .p)

Based on makeproxy-new.php by Bob Maple.
"""

import struct
import sys
from pathlib import Path
from PIL import Image


def png_to_proxy(png_path: str) -> None:
    path = Path(png_path)
    if not path.exists():
        print(f"File not found: {png_path}")
        return
    if path.suffix.lower() != ".png":
        print(f"Input must be a .png file: {png_path}")
        return

    out_path = path.with_suffix(".p")  # e.g. BB_Shader.glsl.png → BB_Shader.glsl.p

    img = Image.open(path).convert("RGB")
    w, h = img.size

    if w % 4 != 0:
        print(f"Error: image width must be divisible by 4 (is {w}). Try 268x194.")
        return

    print(f"Converting {path.name} → {out_path.name}  ({w}x{h})")

    with open(out_path, "wb") as f:

        # ── Header (40 bytes total) ──────────────────────────────────────
        # Magic number 0xFAF0 (big-endian u16) + 2-byte pad
        f.write(struct.pack(">H", 0xFAF0))
        f.write(struct.pack(">H", 0x0000))

        # Version 1.1 as manually byteswapped float (4 bytes)
        ver = struct.pack("f", 1.1)
        f.write(bytes([ver[3], ver[2], ver[1], ver[0]]))

        # Width, Height, Depth=130 as big-endian u16 (6 bytes)
        f.write(struct.pack(">HHH", w, h, 130))

        # 6x big-endian u32 zeros (24 bytes)
        f.write(struct.pack(">IIIIII", 0, 0, 0, 0, 0, 0))

        # 2-byte pad
        f.write(struct.pack(">H", 0))

        # ── Pixel data (upside-down, raw RGB) ────────────────────────────
        pixels = list(img.getdata())
        for row in range(h - 1, -1, -1):
            for col in range(w):
                r, g, b = pixels[row * w + col]
                f.write(struct.pack("BBB", r, g, b))

    print(f"Done.")


if __name__ == "__main__":
    if len(sys.argv) < 2:
        print(__doc__)
        sys.exit(1)
    for arg in sys.argv[1:]:
        png_to_proxy(arg)
