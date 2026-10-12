"""Генератор обложки и баннера для страницы itch.io из фото животных."""
import os
from PIL import Image, ImageDraw, ImageFont, ImageFilter

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', '..')
A = os.path.join(ROOT, 'assets', 'animals')
F = os.path.join(ROOT, 'assets', 'fonts', 'Nunito-Bold.ttf')
OUT = os.path.dirname(os.path.abspath(__file__))


def photo(n, s):
    im = Image.open(os.path.join(A, f'animal_{n}.jpg')).convert('RGB')
    w, h = im.size
    m = min(w, h)
    return im.crop(((w - m) // 2, (h - m) // 2, (w + m) // 2, (h + m) // 2)).resize((s, s))


def cover(W, H, fn):
    bg = Image.new('RGB', (W, H))
    d = ImageDraw.Draw(bg)
    for y in range(H):
        t = y / H
        d.line((0, y, W, y), fill=(int(255 - 40 * t), int(214 - 30 * t), int(120 + 20 * t)))
    names = [n for n in ['fox', 'bear', 'elephant', 'giraffe'] if os.path.exists(os.path.join(A, f'animal_{n}.jpg'))]
    s = int(H * 0.34)
    pos = [(0.04, 0.06, -6), (0.64, 0.05, 5), (0.02, 0.58, 5), (0.68, 0.56, -5)]
    pad = 10
    for n, (px, py, a) in zip(names, pos):
        im = photo(n, s)
        fr = Image.new('RGBA', (s + 2 * pad, s + 2 * pad), (255, 255, 255, 255))
        mk = Image.new('L', fr.size, 0)
        ImageDraw.Draw(mk).rounded_rectangle((0, 0, fr.size[0] - 1, fr.size[1] - 1), s // 8, fill=255)
        fr.putalpha(mk)
        fr.paste(im, (pad, pad))
        fr = fr.rotate(a, expand=True, resample=Image.BICUBIC)
        sh = Image.new('RGBA', fr.size, (0, 0, 0, 0))
        sh.paste((0, 0, 0, 90), mask=fr.split()[3])
        sh = sh.filter(ImageFilter.GaussianBlur(8))
        bg.paste(sh, (int(px * W) + 5, int(py * H) + 8), sh)
        bg.paste(fr, (int(px * W), int(py * H)), fr)
    d = ImageDraw.Draw(bg)

    def ctext(t, y, size, col):
        f = ImageFont.truetype(F, size)
        w = d.textlength(t, font=f)
        d.text(((W - w) / 2, y), t, font=f, fill=col, stroke_width=max(2, size // 14), stroke_fill=(70, 110, 60))

    ctext('МОЙ ЗООПАРК', int(H * 0.30), int(H * 0.13), (255, 255, 255))
    ctext('Учимся читать', int(H * 0.46), int(H * 0.10), (255, 255, 255))
    f = ImageFont.truetype(F, int(H * 0.10))
    ts = int(H * 0.14)
    x0 = (W - ts * 3 - 20) // 2
    y0 = int(H * 0.66)
    for i, ch in enumerate('КОТ'):
        x = x0 + i * (ts + 10)
        d.rounded_rectangle((x, y0, x + ts, y0 + ts), ts // 5, fill=(255, 250, 235), outline=(230, 150, 60), width=4)
        w = d.textlength(ch, font=f)
        d.text((x + (ts - w) / 2, y0 + ts * 0.1), ch, font=f, fill=(200, 90, 40))
    bg.save(os.path.join(OUT, fn))


cover(630, 500, 'cover_630x500.png')
cover(1280, 720, 'banner_1280x720.png')
