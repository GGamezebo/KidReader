# -*- coding: utf-8 -*-
"""Generate Russian voice clips (letter SOUNDS + whole level words) for a kids game.

Voice: Microsoft neural TTS (ru-RU-SvetlanaNeural — warm, friendly) via `edge-tts`.
Needs internet while generating; the game itself ships the resulting .ogg files.

Setup (once):
    python -m venv tools/.venv
    tools/.venv/Scripts/python -m pip install edge-tts numpy soundfile

Run from project root:
    tools/.venv/Scripts/python tools/generate_voice.py             # everything
    tools/.venv/Scripts/python tools/generate_voice.py --only Б СОВА # regenerate some
    tools/.venv/Scripts/python tools/generate_voice.py --voice ru-RU-DmitryNeural

Writes:
    assets/audio/voice/letters/<translit>.ogg
    assets/audio/voice/words/<translit>.ogg
    src/features/sfx/voice_bank.tres   (VoiceBank: letter -> stream, word -> stream)

Words are read from src/levels/*.tres, so rerun after adding a level.
"""
from __future__ import annotations

import argparse
import asyncio
import re
import sys
import tempfile
from pathlib import Path

import edge_tts
import numpy as np
import soundfile as sf

ROOT = Path(__file__).resolve().parent.parent
LETTERS_DIR = ROOT / "assets" / "audio" / "voice" / "letters"
WORDS_DIR = ROOT / "assets" / "audio" / "voice" / "words"
PHRASES_DIR = ROOT / "assets" / "audio" / "voice" / "phrases"
LEVELS_DIR = ROOT / "src" / "levels"
BANK_PATH = ROOT / "src" / "features" / "sfx" / "voice_bank.tres"

VOICE = "ru-RU-SvetlanaNeural"
PITCH = "+5Hz"  # a touch brighter / friendlier

TRANSLIT = {
    "А": "a", "Б": "b", "В": "v", "Г": "g", "Д": "d", "Е": "ye", "Ё": "yo", "Ж": "zh",
    "З": "z", "И": "i", "Й": "j", "К": "k", "Л": "l", "М": "m", "Н": "n", "О": "o",
    "П": "p", "Р": "r", "С": "s", "Т": "t", "У": "u", "Ф": "f", "Х": "kh", "Ц": "ts",
    "Ч": "ch", "Ш": "sh", "Щ": "shch", "Ъ": "hard", "Ы": "y", "Ь": "soft", "Э": "e",
    "Ю": "yu", "Я": "ya",
}

# Letter -> (text for TTS, rate). Phonics: the letter's SOUND, not its name.
# A single consonant ("м", "б") is read as its NAME ("эм", "бэ"), so:
#   vowels / continuants are doubled ("аа", "мм") -> one long, calm sound;
#   stops are a soft whole syllable ("бы") — never cut, just faded out.
LETTER_TEXT: dict[str, tuple[str, str]] = {
    # vowels
    "А": ("аа", "-20%"), "О": ("оо", "-20%"), "У": ("уу", "-20%"), "Ы": ("ыы", "-20%"),
    "Э": ("ээ", "-20%"), "И": ("ии", "-20%"),
    "Е": ("е", "-25%"), "Ё": ("ё", "-25%"), "Ю": ("ю", "-25%"), "Я": ("я", "-25%"),
    # continuants
    "М": ("мм", "-20%"), "Н": ("нн", "-20%"), "Л": ("лл", "-20%"), "Р": ("рр", "-20%"),
    "С": ("сс", "-20%"), "З": ("зз", "-20%"), "Ш": ("шш", "-20%"), "Ж": ("жж", "-20%"),
    "Ф": ("фф", "-20%"), "В": ("вв", "-20%"), "Х": ("хх", "-20%"), "Щ": ("щщ", "-20%"),
    # stops / affricates
    "Б": ("бы", "-20%"), "П": ("пы", "-20%"), "Д": ("ды", "-20%"), "Т": ("ты", "-20%"),
    "Г": ("гы", "-20%"), "К": ("кы", "-20%"), "Ц": ("цы", "-20%"), "Ч": ("чи", "-20%"),
    "Й": ("йи", "-20%"),
    # signs have no sound — say their names
    "Ъ": ("твёрдый знак", "-15%"), "Ь": ("мягкий знак", "-15%"),
}

# Mascot lines: key (used by code via VoiceBank.get_phrase) -> text.
PHRASES = {
    "festival_intro": "Праздник! Прочитай слово и найди зверя!",
    "festival_try_again": "Почти! Прочитай ещё раз.",
    "festival_win": "Ура! Ты прочитал все слова!",
    "zone_unlocked": "Новая зона открыта! Пойдём знакомиться!",
}
PHRASE_RATE = "-15%"

# Whole words: slow, cheerful ("!" gives a lively, praising intonation).
WORD_RATE = "-30%"
WORD_SUFFIX = "!"

TARGET_PEAK = 0.7  # calm, not blasting
LEAD_MS, TAIL_MS = 20, 140  # keep the natural breath/decay at the end
FADE_IN_MS, FADE_OUT_MS = 10, 90


def translit(word: str) -> str:
    return "".join(TRANSLIT.get(ch, "_") for ch in word.upper())


async def tts(text: str, voice: str, rate: str) -> tuple[np.ndarray, int]:
    with tempfile.TemporaryDirectory() as tmp:
        mp3 = Path(tmp) / "clip.mp3"
        await edge_tts.Communicate(text, voice, rate=rate, pitch=PITCH).save(str(mp3))
        a, sr = sf.read(str(mp3), dtype="float32")
    if a.ndim > 1:
        a = a.mean(axis=1)
    return a, sr


def soften(a: np.ndarray, sr: int) -> np.ndarray:
    """Trim silence (keeping natural decay), gentle fades, calm level."""
    idx = np.flatnonzero(np.abs(a) > 0.01 * max(1e-6, np.abs(a).max()))
    if idx.size:
        a = a[max(0, idx[0] - sr * LEAD_MS // 1000): min(a.size, idx[-1] + sr * TAIL_MS // 1000)]
    a = a.copy()
    fi, fo = min(a.size, sr * FADE_IN_MS // 1000), min(a.size, sr * FADE_OUT_MS // 1000)
    a[:fi] *= np.linspace(0.0, 1.0, fi, dtype=np.float32)
    a[-fo:] *= np.linspace(1.0, 0.0, fo, dtype=np.float32) ** 2
    peak = np.abs(a).max()
    return a if peak < 1e-6 else a * (TARGET_PEAK / peak)


def write(path: Path, a: np.ndarray, sr: int) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    sf.write(str(path), a, sr, format="OGG", subtype="VORBIS")


def level_words() -> list[str]:
    words = set()
    for p in sorted(LEVELS_DIR.glob("*.tres")):
        m = re.search(r'^word = "(.+)"$', p.read_text(encoding="utf-8"), re.M)
        if m:
            words.add(m.group(1).upper())
    return sorted(words)


def res_path(p: Path) -> str:
    return "res://" + p.relative_to(ROOT).as_posix()


def write_bank(letters: dict[str, Path], words: dict[str, Path], phrases: dict[str, Path]) -> None:
    ext, ids = [], {}
    for p in list(letters.values()) + list(words.values()) + list(phrases.values()):
        ids[p] = f"{len(ids) + 2}"
        ext.append(f'[ext_resource type="AudioStream" path="{res_path(p)}" id="{ids[p]}"]')

    def dict_body(d: dict[str, Path]) -> str:
        return ", ".join(f'"{k}": ExtResource("{ids[v]}")' for k, v in d.items())

    text = "\n".join([
        f'[gd_resource type="Resource" script_class="VoiceBank" load_steps={len(ids) + 2} format=3]',
        "",
        '[ext_resource type="Script" path="res://src/features/sfx/voice_bank.gd" id="1"]',
        *ext,
        "",
        "[resource]",
        'script = ExtResource("1")',
        f"letters = Dictionary[String, AudioStream]({{{dict_body(letters)}}})",
        f"words = Dictionary[String, AudioStream]({{{dict_body(words)}}})",
        f"phrases = Dictionary[String, AudioStream]({{{dict_body(phrases)}}})",
        "",
    ])
    BANK_PATH.write_text(text, encoding="utf-8")


async def run(voice: str, only: set[str] | None) -> None:
    letters: dict[str, Path] = {}
    for ch, (text, rate) in LETTER_TEXT.items():
        path = LETTERS_DIR / f"{TRANSLIT[ch]}.ogg"
        letters[ch] = path
        if only is not None and ch not in only:
            continue
        a, sr = await tts(text, voice, rate)
        a = soften(a, sr)
        write(path, a, sr)
        print(f"letter {ch} <- '{text}' {rate}  {a.size * 1000 // sr} ms")

    words: dict[str, Path] = {}
    for w in level_words():
        path = WORDS_DIR / f"{translit(w)}.ogg"
        words[w] = path
        if only is not None and w not in only:
            continue
        text = w.capitalize() + WORD_SUFFIX
        a, sr = await tts(text, voice, WORD_RATE)
        a = soften(a, sr)
        write(path, a, sr)
        print(f"word {w} <- '{text}' {WORD_RATE}  {a.size * 1000 // sr} ms")

    phrases: dict[str, Path] = {}
    for key, text in PHRASES.items():
        path = PHRASES_DIR / f"{key}.ogg"
        phrases[key] = path
        if only is not None and key.upper() not in only:
            continue
        a, sr = await tts(text, voice, PHRASE_RATE)
        a = soften(a, sr)
        write(path, a, sr)
        print(f"phrase {key} <- '{text}'  {a.size * 1000 // sr} ms")

    write_bank({k: v for k, v in letters.items() if v.exists()},
               {k: v for k, v in words.items() if v.exists()},
               {k: v for k, v in phrases.items() if v.exists()})
    print(f"Wrote {BANK_PATH.relative_to(ROOT)}")


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--voice", default=VOICE, help="ru-RU-SvetlanaNeural | ru-RU-DmitryNeural")
    ap.add_argument("--only", nargs="*", help="regenerate only these letters/words")
    args = ap.parse_args()
    only = {s.upper() for s in args.only} if args.only else None
    asyncio.run(run(args.voice, only))
    return 0


if __name__ == "__main__":
    sys.exit(main())
