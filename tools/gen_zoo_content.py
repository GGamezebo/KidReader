# -*- coding: utf-8 -*-
"""Generate the zoo campaign data from ONE table: regions → zones → animals.

Run from project root (plain Python 3, no deps):
    python tools/gen_zoo_content.py

Writes (overwrites):
    src/levels/level_<id>.tres          LevelData  (id = zone_number * 100 + index, stable progress key)
    src/levels/zones/zone_<id>.tres     ZoneData
    src/levels/regions/region_<id>.tres RegionData
    src/common/levels_catalog.tres      LevelsCatalog (regions in order)

Photo: assets/animals/animal_<animal_id>.jpg is linked automatically when the file exists.
Never reorder animals inside a zone or zones themselves after release — ids are save keys;
append new animals at the end of a zone instead.
After changing words, rerun tools/generate_voice.py.
"""
from __future__ import annotations

from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
LEVELS_DIR = ROOT / "src" / "levels"
ZONES_DIR = LEVELS_DIR / "zones"
REGIONS_DIR = LEVELS_DIR / "regions"
CATALOG = ROOT / "src" / "common" / "levels_catalog.tres"
PHOTOS = ROOT / "assets" / "animals"

# Region: (id, name, icon, color_top, color_bottom, transition_icon_to_next, festival_cards, difficulty, ghosts, enclosure_style, sky, zones)
#   enclosure_style: fence | ice | dome | palisade (drawn procedurally by the zone screen).
#   ghosts: "all" = ghost letters on every level, "first" = only first level of each zone, "none".
# Zone:   (id, name, icon, color, [(animal_id, WORD), ...])  — animals ordered short → long word.
REGIONS = [
    ("home", "Родные края", "🏡", "FFE3CC", "D9EFC0", "⛵", 3, 1, "all", "fence", "CDEBF7", [
        ("farm", "Домашний двор", "🐄", "F3C969", [
            ("cat", "КОТ"), ("dog", "ПЁС"), ("bull", "БЫК"), ("goat", "КОЗА"), ("horse", "КОНЬ"), ("sheep", "ОВЦА")]),
        ("forest", "Лесная поляна", "🌲", "7DB46C", [
            ("hedgehog", "ЁЖ"), ("fox", "ЛИСА"), ("owl", "СОВА"), ("wolf", "ВОЛК"), ("moose", "ЛОСЬ"),
            ("deer", "ОЛЕНЬ"), ("squirrel", "БЕЛКА")]),
        ("pond", "Пруд и речка", "🦆", "5FC4C0", [
            ("crayfish", "РАК"), ("frog", "ЖАБА"), ("fish", "РЫБА"), ("beaver", "БОБР"), ("heron", "ЦАПЛЯ"),
            ("swan", "ЛЕБЕДЬ")]),
        ("poultry", "Птичий двор", "🐓", "F2A65A", [
            ("goose", "ГУСЬ"), ("duck", "УТКА"), ("turkey", "ИНДЮК"), ("rooster", "ПЕТУХ"), ("hen", "КУРИЦА"),
            ("pigeon", "ГОЛУБЬ")]),
        ("meadow", "Цветочный луг", "🐝", "E88FB0", [
            ("beetle", "ЖУК"), ("wasp", "ОСА"), ("fly", "МУХА"), ("bee", "ПЧЕЛА"), ("mosquito", "КОМАР"),
            ("snail", "УЛИТКА"), ("butterfly", "БАБОЧКА")]),
        ("taiga", "Тайга", "🐻", "4F8A5B", [
            ("lynx", "РЫСЬ"), ("hare", "ЗАЯЦ"), ("boar", "КАБАН"), ("badger", "БАРСУК"), ("sable", "СОБОЛЬ"),
            ("bear", "МЕДВЕДЬ")]),
        ("mountains", "Горы", "🏔️", "9AA7B8", [
            ("yak", "ЯК"), ("eagle", "ОРЁЛ"), ("snow_leopard", "БАРС"), ("llama", "ЛАМА"), ("marmot", "СУРОК"),
            ("ram", "БАРАН")]),
    ]),
    ("warm", "Тёплые страны", "🌴", "FFE3A8", "F3B878", "✈️", 4, 2, "first", "fence", "FFE9C7", [
        ("savanna", "Саванна", "🦁", "E9A05B", [
            ("lion", "ЛЕВ"), ("elephant", "СЛОН"), ("hyena", "ГИЕНА"), ("zebra", "ЗЕБРА"), ("giraffe", "ЖИРАФ"),
            ("rhino", "НОСОРОГ"), ("hippo", "БЕГЕМОТ")]),
        ("desert", "Пустыня", "🐪", "E6C27A", [
            ("cobra", "КОБРА"), ("fennec", "ФЕНЕК"), ("camel", "ВЕРБЛЮД"), ("lizard", "ЯЩЕРИЦА"),
            ("scorpion", "СКОРПИОН"), ("jerboa", "ТУШКАНЧИК")]),
        ("africa_forest", "Африканский лес", "🦍", "5E9E4A", [
            ("okapi", "ОКАПИ"), ("gorilla", "ГОРИЛЛА"), ("leopard", "ЛЕОПАРД"), ("chimpanzee", "ШИМПАНЗЕ"),
            ("chameleon", "ХАМЕЛЕОН")]),
        ("asia", "Азия", "🐼", "D9644A", [
            ("tiger", "ТИГР"), ("panda", "ПАНДА"), ("python", "ПИТОН"), ("peacock", "ПАВЛИН"),
            ("macaque", "МАКАКА"), ("orangutan", "ОРАНГУТАН")]),
        ("amazon", "Джунгли Амазонки", "🦜", "3FA37A", [
            ("toucan", "ТУКАН"), ("jaguar", "ЯГУАР"), ("tapir", "ТАПИР"), ("sloth", "ЛЕНИВЕЦ"),
            ("parrot", "ПОПУГАЙ"), ("anaconda", "АНАКОНДА")]),
        ("australia", "Австралия", "🦘", "D98E4A", [
            ("emu", "ЭМУ"), ("koala", "КОАЛА"), ("dingo", "ДИНГО"), ("wombat", "ВОМБАТ"), ("echidna", "ЕХИДНА"),
            ("kangaroo", "КЕНГУРУ"), ("platypus", "УТКОНОС")]),
        ("islands", "Острова", "🦩", "4FB3C9", [
            ("lemur", "ЛЕМУР"), ("monitor_lizard", "ВАРАН"), ("gecko", "ГЕККОН"), ("iguana", "ИГУАНА"),
            ("pelican", "ПЕЛИКАН"), ("flamingo", "ФЛАМИНГО")]),
    ]),
    ("cold", "Холодные края", "❄️", "EEF7FD", "B9DCF2", "🤿", 6, 3, "none", "ice", "E6F4FB", [
        ("ice", "Ледяной край", "❄️", "9FD3EE", [
            ("walrus", "МОРЖ"), ("nerpa", "НЕРПА"), ("arctic_fox", "ПЕСЕЦ"), ("seal", "ТЮЛЕНЬ"),
            ("narwhal", "НАРВАЛ"), ("penguin", "ПИНГВИН"), ("albatross", "АЛЬБАТРОС")]),
        ("ice_age", "Ледниковый период", "🦣", "B8C6D9", [
            ("aurochs", "ТУР"), ("bison", "БИЗОН"), ("saiga", "САЙГА"), ("mammoth", "МАМОНТ"),
            ("muskox", "ОВЦЕБЫК")]),
    ]),
    ("sea", "Подводный мир", "🐠", "2EC4B6", "22306B", "🌀", 6, 3, "none", "dome", "1F8FB0", [
        ("reef", "Коралловый риф", "🐠", "2EC4B6", [
            ("crab", "КРАБ"), ("stingray", "СКАТ"), ("seahorse", "КОНЁК"), ("moray", "МУРЕНА"),
            ("turtle", "ЧЕРЕПАХА"), ("cuttlefish", "КАРАКАТИЦА")]),
        ("ocean", "Открытый океан", "🐋", "2F80C9", [
            ("whale", "КИТ"), ("shark", "АКУЛА"), ("tuna", "ТУНЕЦ"), ("dolphin", "ДЕЛЬФИН"), ("orca", "КАСАТКА"),
            ("squid", "КАЛЬМАР")]),
        ("deep_sea", "Морская глубина", "🐙", "22306B", [
            ("lobster", "ОМАР"), ("starfish", "ЗВЕЗДА"), ("jellyfish", "МЕДУЗА"), ("shrimp", "КРЕВЕТКА"),
            ("octopus", "ОСЬМИНОГ"), ("anglerfish", "УДИЛЬЩИК")]),
    ]),
    ("lost_world", "Затерянный мир", "🦖", "B5D17A", "F0B27A", "", 6, 3, "none", "palisade", "FFD8B0", [
        ("dino_valley", "Долина динозавров", "🦖", "8DB33A", [
            ("raptor", "РАПТОР"), ("diplodocus", "ДИПЛОДОК"), ("stegosaurus", "СТЕГОЗАВР"),
            ("ankylosaurus", "АНКИЛОЗАВР"), ("triceratops", "ТРИЦЕРАТОПС"), ("tyrannosaurus", "ТИРАННОЗАВР")]),
        ("dino_sea_sky", "Небо и море ящеров", "🦕", "C2553A", [
            ("mosasaurus", "МОЗАЗАВР"), ("ichthyosaurus", "ИХТИОЗАВР"), ("plesiosaurus", "ПЛЕЗИОЗАВР"),
            ("pteranodon", "ПТЕРАНОДОН"), ("pterodactyl", "ПТЕРОДАКТИЛЬ")]),
    ]),
]

# Dino egg on the map (derived from progress, nothing saved): found after this zone's festival,
# one crack per later festival, hatches when the second zone opens.
EGG = ("mountains", "dino_valley")

# Placeholder picture until a real photo exists (stickers, festival cards, level reveal).
EMOJI = {
    "cat": "🐱",
    "dog": "🐶",
    "bull": "🐂",
    "goat": "🐐",
    "horse": "🐴",
    "sheep": "🐑",
    "hedgehog": "🦔",
    "fox": "🦊",
    "owl": "🦉",
    "wolf": "🐺",
    "moose": "🫎",
    "deer": "🦌",
    "squirrel": "🐿️",
    "crayfish": "🦞",
    "frog": "🐸",
    "fish": "🐟",
    "beaver": "🦫",
    "heron": "🪶",
    "swan": "🦢",
    "goose": "🪿",
    "duck": "🦆",
    "turkey": "🦃",
    "rooster": "🐓",
    "hen": "🐔",
    "pigeon": "🕊️",
    "beetle": "🪲",
    "wasp": "🐝",
    "fly": "🪰",
    "bee": "🐝",
    "mosquito": "🦟",
    "snail": "🐌",
    "butterfly": "🦋",
    "lynx": "🐈",
    "hare": "🐇",
    "boar": "🐗",
    "badger": "🦡",
    "sable": "🦦",
    "bear": "🐻",
    "yak": "🐃",
    "eagle": "🦅",
    "snow_leopard": "🐆",
    "llama": "🦙",
    "marmot": "🐹",
    "ram": "🐏",
    "lion": "🦁",
    "elephant": "🐘",
    "hyena": "🐕",
    "zebra": "🦓",
    "giraffe": "🦒",
    "rhino": "🦏",
    "hippo": "🦛",
    "cobra": "🐍",
    "fennec": "🦊",
    "camel": "🐫",
    "lizard": "🦎",
    "scorpion": "🦂",
    "jerboa": "🐁",
    "okapi": "🦓",
    "gorilla": "🦍",
    "leopard": "🐆",
    "chimpanzee": "🐒",
    "chameleon": "🦎",
    "tiger": "🐯",
    "panda": "🐼",
    "python": "🐍",
    "peacock": "🦚",
    "macaque": "🐵",
    "orangutan": "🦧",
    "toucan": "🐦",
    "jaguar": "🐆",
    "tapir": "🐖",
    "sloth": "🦥",
    "parrot": "🦜",
    "anaconda": "🐍",
    "emu": "🐦",
    "koala": "🐨",
    "dingo": "🐕",
    "wombat": "🐻",
    "echidna": "🦔",
    "kangaroo": "🦘",
    "platypus": "🦆",
    "lemur": "🐒",
    "monitor_lizard": "🦎",
    "gecko": "🦎",
    "iguana": "🦎",
    "pelican": "🐦",
    "flamingo": "🦩",
    "walrus": "🦭",
    "nerpa": "🦭",
    "arctic_fox": "🦊",
    "seal": "🦭",
    "narwhal": "🐋",
    "penguin": "🐧",
    "albatross": "🕊️",
    "aurochs": "🐂",
    "bison": "🦬",
    "saiga": "🐐",
    "mammoth": "🦣",
    "muskox": "🐃",
    "crab": "🦀",
    "stingray": "🐟",
    "seahorse": "🐠",
    "moray": "🐍",
    "turtle": "🐢",
    "cuttlefish": "🦑",
    "whale": "🐋",
    "shark": "🦈",
    "tuna": "🐟",
    "dolphin": "🐬",
    "orca": "🐋",
    "squid": "🦑",
    "lobster": "🦞",
    "starfish": "⭐",
    "jellyfish": "🪼",
    "shrimp": "🦐",
    "octopus": "🐙",
    "anglerfish": "🐡",
    "raptor": "🦖",
    "diplodocus": "🦕",
    "stegosaurus": "🦕",
    "ankylosaurus": "🦕",
    "triceratops": "🦕",
    "tyrannosaurus": "🦖",
    "mosasaurus": "🐊",
    "ichthyosaurus": "🐬",
    "plesiosaurus": "🦕",
    "pteranodon": "🦅",
    "pterodactyl": "🦅",
}

MAX_WORD = 12


def color(hex_: str) -> str:
    h = hex_.lstrip("#")
    r, g, b = (int(h[i:i + 2], 16) / 255 for i in (0, 2, 4))
    return f"Color({r:.4g}, {g:.4g}, {b:.4g}, 1)"


def q(s: str) -> str:
    return '"' + s.replace("\\", "\\\\").replace('"', '\\"') + '"'


def res(path: Path) -> str:
    return "res://" + path.relative_to(ROOT).as_posix()


def write_level(level_id: int, animal_id: str, word: str, ghosts: bool, difficulty: int) -> Path:
    assert animal_id in EMOJI, f"no emoji for {animal_id}"
    path = LEVELS_DIR / f"level_{level_id}.tres"
    photo = PHOTOS / f"animal_{animal_id}.jpg"
    ext = ['[ext_resource type="Script" path="res://src/common/level_data.gd" id="1"]']
    tex_line = ""
    if photo.exists():
        ext.append(f'[ext_resource type="Texture2D" path="{res(photo)}" id="2"]')
        tex_line = 'animal_texture = ExtResource("2")\n'
    parts = ", ".join(q(ch) for ch in word)
    path.write_text(
        f'[gd_resource type="Resource" script_class="LevelData" load_steps={len(ext) + 1} format=3]\n\n'
        + "\n".join(ext) + "\n\n[resource]\n"
        + 'script = ExtResource("1")\n'
        + f"level_id = {level_id}\n"
        + f"animal_id = {q(animal_id)}\n"
        + f"animal_display_name = {q(word.capitalize())}\n"
        + f"word = {q(word)}\n"
        + f"emoji = {q(EMOJI[animal_id])}\n"
        + f"parts = PackedStringArray({parts})\n"
        + tex_line
        + f"show_ghost_hints = {'true' if ghosts else 'false'}\n"
        + f"difficulty = {difficulty}\n",
        encoding="utf-8")
    return path


def write_list_resource(path: Path, script: str, cls: str, fields: list[str], list_field: str,
                        items: list[Path]) -> None:
    ext = [f'[ext_resource type="Script" path="{script}" id="1"]']
    refs = []
    for i, item in enumerate(items):
        ext.append(f'[ext_resource type="Resource" path="{res(item)}" id="r{i}"]')
        refs.append(f'ExtResource("r{i}")')
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(
        f'[gd_resource type="Resource" script_class="{cls}" load_steps={len(ext) + 1} format=3]\n\n'
        + "\n".join(ext) + "\n\n[resource]\n"
        + 'script = ExtResource("1")\n'
        + "".join(f + "\n" for f in fields)
        + f"{list_field} = [{', '.join(refs)}]\n",
        encoding="utf-8")


def main() -> None:
    LEVELS_DIR.mkdir(parents=True, exist_ok=True)
    for old in LEVELS_DIR.glob("level_*.tres"):
        old.unlink()
    for d in (ZONES_DIR, REGIONS_DIR):
        if d.exists():
            for old in d.glob("*.tres"):
                old.unlink()

    seen_animals: set[str] = set()
    region_paths: list[Path] = []
    zone_number = 0
    total = with_photo = 0
    for (rid, rname, ricon, rtop, rbottom, rhop, cards, difficulty, ghosts, enclosure, sky, zones) in REGIONS:
        zone_paths: list[Path] = []
        for (zid, zname, zicon, zcolor, animals) in zones:
            zone_number += 1
            level_paths = []
            for idx, (aid, word) in enumerate(animals, start=1):
                assert aid not in seen_animals, f"duplicate animal id {aid}"
                assert len(word) <= MAX_WORD, f"{word} longer than {MAX_WORD}"
                seen_animals.add(aid)
                show_ghost = ghosts == "all" or (ghosts == "first" and idx == 1)
                level_paths.append(write_level(zone_number * 100 + idx, aid, word, show_ghost, difficulty))
                total += 1
                with_photo += (PHOTOS / f"animal_{aid}.jpg").exists()
            zpath = ZONES_DIR / f"zone_{zid}.tres"
            write_list_resource(zpath, "res://src/common/zone_data.gd", "ZoneData", [
                f"zone_id = {q(zid)}", f"display_name = {q(zname)}", f"icon = {q(zicon)}",
                f"color = {color(zcolor)}", f"festival_cards = {cards}",
            ], "levels", level_paths)
            zone_paths.append(zpath)
        rpath = REGIONS_DIR / f"region_{rid}.tres"
        write_list_resource(rpath, "res://src/common/region_data.gd", "RegionData", [
            f"region_id = {q(rid)}", f"display_name = {q(rname)}", f"icon = {q(ricon)}",
            f"color_top = {color(rtop)}", f"color_bottom = {color(rbottom)}",
            f"transition_icon = {q(rhop)}", f"enclosure_style = {q(enclosure)}", f"sky_color = {color(sky)}",
        ], "zones", zone_paths)
        region_paths.append(rpath)

    write_list_resource(CATALOG, "res://src/common/levels_catalog.gd", "LevelsCatalog", [
        f"egg_found_after = {q(EGG[0])}", f"egg_hatch_zone = {q(EGG[1])}"], "regions",
                        region_paths)
    assert all(any(z[0] == e for r in REGIONS for z in r[-1]) for e in EGG), "EGG zones must exist"
    print(f"{len(region_paths)} regions, {zone_number} zones, {total} levels ({with_photo} with photo)")


if __name__ == "__main__":
    main()
