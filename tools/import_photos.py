# -*- coding: utf-8 -*-
"""Import generated animal pictures into the game.

Run from project root (needs Pillow: pip install pillow):
    python tools/import_photos.py            # import everything in tools/photo_inbox/
    python tools/import_photos.py --replace  # also overwrite photos that already exist

Inbox file name = animal id (`fox.png`, `animal_fox.webp`) or the Russian word (`лиса.jpg`).
Each picture is centre-cropped to 16:9, resized to 1280×720 and saved as assets/animals/animal_<id>.jpg;
the original moves to tools/photo_inbox/done/. Then levels are regenerated so the photos get linked.
Prompts for the pictures: tools/gen_photo_prompts.py → concepts/photo_prompts.md.
"""
from __future__ import annotations

import shutil
import sys
from pathlib import Path

from PIL import Image

import gen_zoo_content
from gen_zoo_content import PHOTOS, REGIONS, ROOT

INBOX = ROOT / "tools" / "photo_inbox"
DONE = INBOX / "done"
SIZE = (1280, 720)
EXTS = {".png", ".jpg", ".jpeg", ".webp"}


def animal_lookup() -> dict[str, str]:
    """Every accepted file stem → animal id."""
    out: dict[str, str] = {}
    for (*_r, zones) in REGIONS:
        for (*_z, animals) in zones:
            for aid, word in animals:
                out[aid] = aid
                out[f"animal_{aid}"] = aid
                out[word.lower()] = aid
                out[word.lower().replace("ё", "е")] = aid
    return out


def crop_16_9(img: Image.Image) -> Image.Image:
    w, h = img.size
    target = SIZE[0] / SIZE[1]
    if w / h > target:
        nw = round(h * target)
        left = (w - nw) // 2
        img = img.crop((left, 0, left + nw, h))
    else:
        nh = round(w / target)
        top = (h - nh) // 2
        img = img.crop((0, top, w, top + nh))
    return img.resize(SIZE, Image.LANCZOS)


def main() -> None:
    replace = "--replace" in sys.argv
    INBOX.mkdir(exist_ok=True)
    lookup = animal_lookup()
    imported = skipped = 0
    for f in sorted(INBOX.iterdir()):
        if not f.is_file() or f.suffix.lower() not in EXTS:
            continue
        aid = lookup.get(f.stem.lower())
        if aid is None:
            print(f"?  {f.name}: unknown animal (use the id from concepts/photo_prompts.md)")
            skipped += 1
            continue
        dst = PHOTOS / f"animal_{aid}.jpg"
        if dst.exists() and not replace:
            print(f"=  {f.name}: {dst.name} exists (pass --replace to overwrite)")
            skipped += 1
            continue
        with Image.open(f) as img:
            crop_16_9(img.convert("RGB")).save(dst, "JPEG", quality=88, optimize=True)
        DONE.mkdir(exist_ok=True)
        shutil.move(str(f), DONE / f.name)
        print(f"+  {f.name} -> {dst.relative_to(ROOT)}")
        imported += 1
    print(f"imported {imported}, skipped {skipped}")
    if imported:
        gen_zoo_content.main()


if __name__ == "__main__":
    main()
