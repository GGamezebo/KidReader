# -*- coding: utf-8 -*-
"""Generate Russian voice clips (letter SOUNDS + whole level words) for a kids game.

Voice: Azure AI Speech neural TTS (ru-RU-SvetlanaNeural — warm, friendly), licensed
for shipping in the game. Free tier F0 (0.5M chars/month) covers a full run (~8K chars).
Words are spoken inside a carrier phrase ("Слово — сова.") and cut out by the TTS word
boundaries: an isolated word gets odd prosody. Letter sounds are SSML <phoneme> (IPA):
plain text "м" is read as the letter NAME ("эм").
Needs internet while generating; the game itself ships the resulting .ogg files.

Setup (once):
    python -m venv tools/.venv
    tools/.venv/Scripts/python -m pip install azure-cognitiveservices-speech numpy soundfile
    Key + region of the Azure Speech resource as user env vars (never in the repo):
    AZURE_SPEECH_KEY, AZURE_SPEECH_REGION (e.g. northeurope)

Run from project root:
    tools/.venv/Scripts/python tools/generate_voice.py             # everything
    tools/.venv/Scripts/python tools/generate_voice.py --only Б СОВА # regenerate some (letters, WORDS, phrase keys, animal ids)
    tools/.venv/Scripts/python tools/generate_voice.py --missing     # only clips that do not exist yet
    tools/.venv/Scripts/python tools/generate_voice.py --voice ru-RU-DmitryNeural

Writes:
    assets/audio/voice/letters/<translit>.ogg
    assets/audio/voice/words/<translit>.ogg
    assets/audio/voice/phrases/<key>.ogg
    assets/audio/voice/facts/<animal_id>.ogg  (album fact per animal, from LevelData.fact)
    src/features/sfx/voice_bank.tres   (VoiceBank: letters, words, phrases, facts)

Words and facts are read from src/levels/*.tres, so rerun after adding a level.
"""
from __future__ import annotations

import argparse
import io
import os
import re
import sys
from pathlib import Path
from xml.sax.saxutils import escape

import azure.cognitiveservices.speech as speechsdk
import numpy as np
import soundfile as sf

ROOT = Path(__file__).resolve().parent.parent
LETTERS_DIR = ROOT / "assets" / "audio" / "voice" / "letters"
WORDS_DIR = ROOT / "assets" / "audio" / "voice" / "words"
PHRASES_DIR = ROOT / "assets" / "audio" / "voice" / "phrases"
FACTS_DIR = ROOT / "assets" / "audio" / "voice" / "facts"
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

# Letter -> (IPA for SSML <phoneme>, stretch). Phonics: the letter's SOUND, not its name.
# One phoneme only: repeats ("mmm") come out as separate pulses ("м-м-м"), and length
# marks / slow rates are ignored. So long sounds are time-stretched afterwards:
#   VOICED — м н л й: WSOLA ("ммм"); vowels keep their natural ~350-500 ms;
#   HISS — с ш ф х щ: noise grains (WSOLA makes hiss "chewed");
#   "" — no stretch: stops (one short sound, no added vowel: "б", not "бэ"/"бы"),
#        and в з ж р (voice + noise / trill rattle under either stretch).
LETTER_RATE = "-20%"
LONG_SOUND_MS = 550  # target length of a long sound (stretch is capped at MAX_STRETCH)
MAX_STRETCH = 2.5
VOICED, HISS = "voiced", "hiss"
HISS_CUT_DB = -9.0  # level cut for a clip with all energy above 5 kHz (see tame_hiss)
# Vowels: plain text with a stress mark — a lone vowel letter is read as its sound and is
# cleaner than IPA (IPA "i" came out jumpy with a long hiss); without the stress mark it is
# reduced ("о" -> "а", "ы" ~ "и").
LETTER_VOWELS = "АОУЫЭИЕЁЮЯ"
STRESS = "́"
LETTER_IPA: dict[str, tuple[str, str]] = {
    # continuants
    "М": ("m", VOICED), "Н": ("n", VOICED), "Л": ("ɫ", VOICED), "Й": ("j", VOICED),
    "С": ("s", HISS), "Ш": ("ʂ", HISS), "Ф": ("f", HISS), "Х": ("x", HISS), "Щ": ("ɕ", HISS),
    "З": ("zz", ""), "Ж": ("ʐʐ", ""), "В": ("v", ""), "Р": ("rrrr", ""),  # see HELPER_VOWEL
    # stops / affricates
    "Б": ("b", ""), "П": ("p", ""), "Д": ("d", ""), "Т": ("t", ""),
    "Г": ("ɡ", ""), "К": ("k", ""), "Ц": ("t͡s", ""), "Ч": ("t͡ɕ", ""),
}
# Said with a helper vowel that is then cut off ("zə" -> "з"). Alone, З Ж come out devoiced
# (final devoicing: "з" -> "с"), П Т К end in a long flat hiss (a real "п" is a burst + a
# fading hint of vowel), Р is one tap. Letter -> ms of the helper vowel kept (faded out).
HELPER_VOWEL = "ə"
# Before the vowel a repeat is one long sound, not pulses: "zz" -> "ззз", "rrrr" -> rolled "рррр".
HELPER_KEEP_MS = {"З": 0, "Ж": 0, "Р": 0, "П": 110, "Т": 110, "К": 110}
# Signs have no sound — say their names (plain text).
LETTER_NAMES = {"Ъ": "твёрдый знак", "Ь": "мягкий знак"}
NAME_RATE = "-15%"

# Mascot lines: key (used by code via VoiceBank.get_phrase) -> text.
PHRASES = {
    "festival_intro": "Праздник! Прочитай слово и найди зверя!",
    "festival_try_again": "Почти! Прочитай ещё раз.",
    "festival_win": "Ура! Ты прочитал все слова!",
    "zone_unlocked": "Новая зона открыта! Пойдём знакомиться!",
    "egg_mystery": "Что же там? Открой все зоны Родных краёв!",
    "egg_found": "Ой! Огромное яйцо! Кто же в нём живёт?",
    "egg_crack": "Яйцо треснуло! Скоро кто-то вылупится!",
    "egg_wait": "Яйцо растёт. После каждого праздника — новая трещинка!",
    "egg_hatched": "Ура! Вылупился малыш-динозаврик!",
    "album_empty": "Этот зверь ещё не приехал в зоопарк. Собери его слово!",
    "review_hint": "Кто-то соскучился по тебе! Нажми на облачко!",
    "decor_hint": "За звёздочки открываются украшения. Перетащи их в свой зоопарк!",
}
PHRASE_RATE = "-15%"
FACT_RATE = "-15%"

# Whole words: last word of WORD_CARRIER (calm statement intonation), cut out.
# Mild slow-down only: strong rates stretch the audio into "rubber" artifacts.
WORD_CARRIER = "Слово —"
WORD_RATE = "-15%"
CUT_LEAD_MS = 50  # before the word boundary; the carrier pause is ~300 ms

TARGET_PEAK = 0.7  # calm, not blasting
LEAD_MS, TAIL_MS = 20, 140  # keep the natural breath/decay at the end
FADE_IN_MS, FADE_OUT_MS = 10, 90


def translit(word: str) -> str:
    return "".join(TRANSLIT.get(ch, "_") for ch in word.upper())


def env(name: str) -> str:
    """Process env, else the Windows user env (set after this shell started)."""
    if os.environ.get(name):
        return os.environ[name]
    if sys.platform == "win32":
        import winreg
        try:
            with winreg.OpenKey(winreg.HKEY_CURRENT_USER, "Environment") as k:
                return str(winreg.QueryValueEx(k, name)[0])
        except OSError:
            pass
    sys.exit(f"Set {name} (Azure Speech resource key / region), see the header of this script.")


_synth: speechsdk.SpeechSynthesizer | None = None


def synth() -> speechsdk.SpeechSynthesizer:
    global _synth
    if _synth is None:
        cfg = speechsdk.SpeechConfig(subscription=env("AZURE_SPEECH_KEY"), region=env("AZURE_SPEECH_REGION"))
        cfg.set_speech_synthesis_output_format(speechsdk.SpeechSynthesisOutputFormat.Riff24Khz16BitMonoPcm)
        _synth = speechsdk.SpeechSynthesizer(speech_config=cfg, audio_config=None)
    return _synth


def ssml(body: str, voice: str, rate: str) -> str:
    return ('<speak version="1.0" xmlns="http://www.w3.org/2001/10/synthesis" xml:lang="ru-RU">'
            f'<voice name="{voice}"><prosody rate="{rate}" pitch="{PITCH}">{body}</prosody></voice></speak>')


def tts_bounds(body: str, voice: str, rate: str) -> tuple[np.ndarray, int, list[float]]:
    """SSML `body` -> audio + start time (seconds) of every spoken word."""
    s = synth()
    starts: list[float] = []

    def on_word(evt: speechsdk.SpeechSynthesisWordBoundaryEventArgs) -> None:
        if evt.boundary_type == speechsdk.SpeechSynthesisBoundaryType.Word:
            starts.append(evt.audio_offset / 1e7)  # 100 ns ticks

    s.synthesis_word_boundary.connect(on_word)
    try:
        r = s.speak_ssml_async(ssml(body, voice, rate)).get()
    finally:
        s.synthesis_word_boundary.disconnect_all()
    if r.reason != speechsdk.ResultReason.SynthesizingAudioCompleted:
        d = r.cancellation_details
        raise RuntimeError(f"Azure TTS failed: {d.reason} {d.error_details}")
    a, sr = sf.read(io.BytesIO(r.audio_data), dtype="float32")
    if a.ndim > 1:
        a = a.mean(axis=1)
    return a, sr, starts


def tts(text: str, voice: str, rate: str) -> tuple[np.ndarray, int]:
    a, sr, _ = tts_bounds(escape(text), voice, rate)
    return a, sr


def tts_phoneme(ipa: str, voice: str, rate: str) -> tuple[np.ndarray, int]:
    a, sr, _ = tts_bounds(f'<phoneme alphabet="ipa" ph="{escape(ipa)}">а</phoneme>', voice, rate)
    return a, sr


def tts_in_carrier(carrier: str, text: str, voice: str, rate: str) -> tuple[np.ndarray, int]:
    """Say `carrier text.` and keep only `text` (it is last, so its decay is kept whole)."""
    a, sr, starts = tts_bounds(escape(f"{carrier} {text}."), voice, rate)
    i = len(re.findall(r"\w+", carrier))
    if i >= len(starts):
        raise RuntimeError(f"no word boundary for '{text}' in '{carrier} {text}.'")
    return a[max(0, int((starts[i] - CUT_LEAD_MS / 1000) * sr)):], sr


def soften(a: np.ndarray, sr: int) -> np.ndarray:
    """Trim silence (keeping natural decay), gentle fades, calm level."""
    # Start: first 10 ms frame with real energy (skips the carrier pause noise / breath).
    w = sr // 100
    rms = np.sqrt(np.convolve(a * a, np.ones(w) / w, mode="valid")) if a.size > w else np.abs(a)
    head = np.flatnonzero(rms > 0.15 * max(1e-6, rms.max()))
    tail = np.flatnonzero(np.abs(a) > 0.01 * max(1e-6, np.abs(a).max()))
    if head.size:
        a = a[max(0, head[0] - sr * LEAD_MS // 1000): min(a.size, tail[-1] + sr * TAIL_MS // 1000)]
    a = a.copy()
    fi, fo = min(a.size, sr * FADE_IN_MS // 1000), min(a.size, sr * FADE_OUT_MS // 1000)
    a[:fi] *= np.linspace(0.0, 1.0, fi, dtype=np.float32)
    a[-fo:] *= np.linspace(1.0, 0.0, fo, dtype=np.float32) ** 2
    peak = np.abs(a).max()
    return a if peak < 1e-6 else a * (TARGET_PEAK / peak)


def wsola(x: np.ndarray, sr: int, factor: float, n: int) -> np.ndarray:
    """`n` samples of `x` time-stretched by `factor`, keeping pitch: overlap-add windows,
    each picked (within a small tolerance) to best continue the previous one.
    `x` should run past the stretched part, so the last windows read real sound."""
    frame = int(0.03 * sr)
    hop_out, tol = frame // 2, int(0.008 * sr)
    hop_in = hop_out / factor
    win = np.hanning(frame).astype(np.float32)
    xp = np.concatenate([np.zeros(tol, np.float32), x, np.zeros(frame + 2 * tol, np.float32)])
    out = np.zeros(n + frame, np.float32)
    norm = np.zeros(n + frame, np.float32)
    prev = None
    for k in range((n + hop_out - 1) // hop_out):
        target = int(k * hop_in) + tol
        if prev is None:
            pos = target
        else:
            nat = xp[prev + hop_out: prev + hop_out + frame]
            lo, hi = max(0, target - tol), min(len(xp) - frame, target + tol)
            scores = [float(np.dot(nat, xp[p:p + frame])) for p in range(lo, hi + 1)]
            pos = lo + int(np.argmax(scores))
        out[k * hop_out: k * hop_out + frame] += xp[pos:pos + frame] * win
        norm[k * hop_out: k * hop_out + frame] += win
        prev = pos
    return (out / np.maximum(norm, 1e-3))[:n]


def stretch_noise(x: np.ndarray, sr: int, factor: float, n: int) -> np.ndarray:
    """Like `wsola`, for hiss ("с", "ш"): noise has no period to align, and WSOLA's search
    makes it flutter ("chewed"). Grains at randomly jittered positions, joined with
    power-complementary (sqrt-Hann) windows, keep the hiss steady."""
    frame = int(0.04 * sr)
    hop_out, jitter = frame // 2, int(0.01 * sr)
    hop_in = hop_out / factor
    win = np.sqrt(np.hanning(frame + 1)[:frame]).astype(np.float32)
    xp = np.concatenate([x, np.zeros(frame + jitter, np.float32)])
    rng = np.random.default_rng(len(x))  # reproducible clips
    out = np.zeros(n + frame, np.float32)
    for k in range((n + hop_out - 1) // hop_out):
        pos = int(k * hop_in) + (int(rng.integers(0, jitter)) if k else 0)
        out[k * hop_out: k * hop_out + frame] += xp[pos:pos + frame] * win
    out[:hop_out] = xp[:hop_out]  # the first grain's rising half has no partner
    return out[:n]


def tame_hiss(a: np.ndarray, sr: int) -> np.ndarray:
    """Hiss normalized like a vowel sounds piercing ("с", "з": ~all energy above 5 kHz);
    in speech it is much quieter. Soften the very top and lower the level by the share
    of high-frequency energy (с, з ~ -9 dB, ш щ ф ~ -4 dB, vowels untouched)."""
    spec = np.abs(np.fft.rfft(a)) ** 2
    freqs = np.fft.rfftfreq(a.size, 1 / sr)
    high = float(spec[freqs > 5000].sum() / max(1e-12, spec.sum()))
    k = 1 - np.exp(-2 * np.pi * 7000 / sr)  # one-pole low-pass at ~7 kHz, mixed in half
    lp = np.empty_like(a)
    acc = 0.0
    for i, v in enumerate(a):
        acc += k * (v - acc)
        lp[i] = acc
    a = a * (1 - 0.5 * high) + lp * (0.5 * high)
    return a * 10 ** (HISS_CUT_DB * high / 20)


def trim_noise_tail(a: np.ndarray, sr: int) -> np.ndarray:
    """Cut the quiet hiss Azure appends after a lone phoneme (up to ~1.5 s after "п", "ф")."""
    w = sr // 100
    rms = np.sqrt(np.convolve(a * a, np.ones(w) / w, mode="same"))
    loud = np.flatnonzero(rms > 0.1 * rms.max())
    return a if loud.size == 0 else a[: loud[-1] + sr * TAIL_MS // 1000]


def last_vowel_start(a: np.ndarray, sr: int) -> int:
    """Sample where the final vowel begins: the last run (>= 40 ms) of 10 ms steps whose
    20 ms window is periodic (voice) with a low spectral centroid (not a fricative)."""
    h = sr // 100
    lo, hi = sr // 400, sr // 70
    floor = 0.02 * np.abs(a).max()
    kinds = []
    for i in range(0, a.size - 2 * h, h):
        x = a[i:i + 2 * h] - a[i:i + 2 * h].mean()
        if np.sqrt(np.mean(x * x)) < floor:
            kinds.append(".")
            continue
        ac = np.correlate(x, x, "full")[x.size - 1:]
        spec = np.abs(np.fft.rfft(x * np.hanning(x.size))) ** 2
        cent = (spec * np.fft.rfftfreq(x.size, 1 / sr)).sum() / (spec.sum() + 1e-12)
        kinds.append("v" if ac[lo:hi].max() / (ac[0] + 1e-12) > 0.6 and cent < 2000 else "n")
    k = "".join(kinds)
    i = k.rfind("vvvv")
    if i < 0:
        return a.size
    while i > 0 and k[i - 1] == "v":
        i -= 1
    return i * h


def cut_helper_vowel(a: np.ndarray, sr: int, keep_ms: int) -> np.ndarray:
    """Cut the helper vowel off, keeping `keep_ms` of it as a fading tail."""
    end = min(a.size, last_vowel_start(a, sr) + sr * keep_ms // 1000)
    a = a[:end].copy()
    f = min(a.size, sr * max(25, keep_ms) // 1000)
    a[-f:] *= np.linspace(1.0, 0.0, f, dtype=np.float32) ** 2
    return a


def lengthen(a: np.ndarray, sr: int, noise: bool = False) -> np.ndarray:
    """Stretch the steady core of a short sound (onset and decay stay natural)."""
    w = sr // 100
    rms = np.sqrt(np.convolve(a * a, np.ones(w) / w, mode="same"))
    loud = np.flatnonzero(rms > 0.5 * rms.max())
    if loud.size < 2:
        return a
    span = loud[-1] - loud[0]
    s0 = loud[0] + span * 3 // 10  # skip the onset (and the "й" glide of е/ё/ю/я)
    s1 = loud[0] + span * 8 // 10  # keep the natural decay whole
    sound_ms = (loud[-1] - loud[0]) * 1000 / sr
    factor = min(MAX_STRETCH, LONG_SOUND_MS / max(1.0, sound_ms))
    extra = (factor * sound_ms - sound_ms) * sr / 1000
    if extra <= 0 or s1 <= s0:
        return a
    xf = sr * 15 // 1000  # crossfade into the natural decay
    n = int(s1 - s0 + extra)
    core = (stretch_noise if noise else wsola)(a[s0:], sr, n / (s1 - s0), n + xf)
    tail = a[s1:]
    if tail.size < xf:
        return np.concatenate([a[:s0], core[:n]])
    ramp = np.linspace(0.0, 1.0, xf, dtype=np.float32)
    blend = core[n:] * (1 - ramp) + tail[:xf] * ramp
    return np.concatenate([a[:s0], core[:n], blend, tail[xf:]])


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


def level_facts() -> dict[str, str]:
    facts = {}
    for p in sorted(LEVELS_DIR.glob("*.tres")):
        text = p.read_text(encoding="utf-8")
        aid = re.search(r'^animal_id = "(.+)"$', text, re.M)
        fact = re.search(r'^fact = "(.+)"$', text, re.M)
        if aid and fact:
            facts[aid.group(1)] = fact.group(1)
    return facts


def res_path(p: Path) -> str:
    return "res://" + p.relative_to(ROOT).as_posix()


def write_bank(letters: dict[str, Path], words: dict[str, Path], phrases: dict[str, Path],
               facts: dict[str, Path]) -> None:
    ext, ids = [], {}
    for p in list(letters.values()) + list(words.values()) + list(phrases.values()) + list(facts.values()):
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
        f"facts = Dictionary[String, AudioStream]({{{dict_body(facts)}}})",
        "",
    ])
    BANK_PATH.write_text(text, encoding="utf-8")


def run(voice: str, only: set[str] | None, missing: bool) -> None:
    def skip(key: str, path: Path) -> bool:
        return (only is not None and key not in only) or (missing and path.exists())

    letters: dict[str, Path] = {}
    for ch in TRANSLIT:
        path = LETTERS_DIR / f"{TRANSLIT[ch]}.ogg"
        letters[ch] = path
        if skip(ch, path):
            continue
        if ch in LETTER_NAMES:
            src = LETTER_NAMES[ch]
            a, sr = tts(src, voice, NAME_RATE)
        elif ch in LETTER_VOWELS:
            src = ch.lower() if ch == "Ё" else ch.lower() + STRESS  # "ё" is always stressed
            a, sr = tts(src, voice, LETTER_RATE)
            a = trim_noise_tail(soften(a, sr), sr)
        else:
            src, stretch = LETTER_IPA[ch]
            if ch in HELPER_KEEP_MS:
                src += HELPER_VOWEL
                a, sr = tts_phoneme(src, voice, LETTER_RATE)
                a = cut_helper_vowel(soften(a, sr), sr, HELPER_KEEP_MS[ch])
            else:
                a, sr = tts_phoneme(src, voice, LETTER_RATE)
            a = trim_noise_tail(soften(a, sr), sr)
            if stretch:
                a = lengthen(a, sr, noise=stretch == HISS)
            a = tame_hiss(soften(a, sr), sr)
        a = a if ch in LETTER_IPA else soften(a, sr)
        write(path, a, sr)
        print(f"letter {ch} <- '{src}'  {a.size * 1000 // sr} ms")

    words: dict[str, Path] = {}
    for w in level_words():
        path = WORDS_DIR / f"{translit(w)}.ogg"
        words[w] = path
        if skip(w, path):
            continue
        text = w.lower()
        a, sr = tts_in_carrier(WORD_CARRIER, text, voice, WORD_RATE)
        a = soften(a, sr)
        write(path, a, sr)
        print(f"word {w} <- '{text}' {WORD_RATE}  {a.size * 1000 // sr} ms")

    phrases: dict[str, Path] = {}
    for key, text in PHRASES.items():
        path = PHRASES_DIR / f"{key}.ogg"
        phrases[key] = path
        if skip(key.upper(), path):
            continue
        a, sr = tts(text, voice, PHRASE_RATE)
        a = soften(a, sr)
        write(path, a, sr)
        print(f"phrase {key} <- '{text}'  {a.size * 1000 // sr} ms")

    facts: dict[str, Path] = {}
    for aid, text in level_facts().items():
        path = FACTS_DIR / f"{aid}.ogg"
        facts[aid] = path
        if skip(aid.upper(), path):
            continue
        a, sr = tts(text, voice, FACT_RATE)
        a = soften(a, sr)
        write(path, a, sr)
        print(f"fact {aid}  {a.size * 1000 // sr} ms")

    write_bank({k: v for k, v in letters.items() if v.exists()},
               {k: v for k, v in words.items() if v.exists()},
               {k: v for k, v in phrases.items() if v.exists()},
               {k: v for k, v in facts.items() if v.exists()})
    print(f"Wrote {BANK_PATH.relative_to(ROOT)}")


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--voice", default=VOICE, help="ru-RU-SvetlanaNeural | ru-RU-DmitryNeural")
    ap.add_argument("--only", nargs="*", help="regenerate only these letters / words / phrase keys / animal ids")
    ap.add_argument("--missing", action="store_true", help="generate only clips that do not exist yet")
    args = ap.parse_args()
    only = {s.upper() for s in args.only} if args.only else None
    run(args.voice, only, args.missing)
    return 0


if __name__ == "__main__":
    sys.exit(main())
