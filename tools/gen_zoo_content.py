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

# One short true fact per animal: shown + voiced in the album (rerun tools/generate_voice.py after edits).
FACTS = {
    "cat": "Кошка мурлычет, когда ей хорошо и спокойно.",
    "dog": "Нюх у собаки в тысячи раз лучше, чем у человека.",
    "bull": "Бык — папа телёнка, а мама — корова.",
    "goat": "Козы ловко лазают по скалам и даже по деревьям.",
    "horse": "Лошадь умеет спать стоя.",
    "sheep": "Из шерсти овцы вяжут тёплые свитера и носки.",
    "hedgehog": "На спинке у ежа тысячи колючих иголок.",
    "fox": "Лиса слышит, как мышка шуршит под снегом.",
    "owl": "Сова может повернуть голову почти назад.",
    "wolf": "Волки живут семьёй — стаей — и вместе воют.",
    "moose": "Лось — самый большой олень на свете.",
    "deer": "Каждый год олень сбрасывает рога, и вырастают новые.",
    "squirrel": "Белка прячет орехи на зиму, а потом ищет их.",
    "crayfish": "Рак уплывает задом наперёд, взмахивая хвостом.",
    "frog": "Жаба ловит мух длинным липким языком.",
    "fish": "Рыбы дышат жабрами прямо в воде.",
    "beaver": "Бобр строит из веток плотины и домики на воде.",
    "heron": "Цапля долго стоит на одной ноге и ждёт рыбку.",
    "swan": "Лебеди выбирают себе пару на всю жизнь.",
    "goose": "Гуси громко гогочут, когда охраняют свой двор.",
    "duck": "Перья утки не намокают в воде.",
    "turkey": "Индюк распускает хвост веером, чтобы казаться больше.",
    "rooster": "Петух громко кукарекает рано утром.",
    "hen": "Курица несёт яйца, из которых могут вылупиться цыплята.",
    "pigeon": "Голуби всегда находят дорогу домой.",
    "beetle": "У жука есть крылья — они спрятаны под твёрдой спинкой.",
    "wasp": "Оса строит домик из бумаги, которую делает сама.",
    "fly": "Муха пробует еду лапками.",
    "bee": "Пчёлы собирают нектар с цветов и делают мёд.",
    "mosquito": "Пищит у комара не голос, а быстрые крылышки.",
    "snail": "Улитка носит свой домик на спине.",
    "butterfly": "Бабочка сначала была гусеницей.",
    "lynx": "У рыси на ушах смешные кисточки.",
    "hare": "Зимой заяц меняет серую шубку на белую.",
    "boar": "Кабан ищет еду, роя землю пятачком.",
    "badger": "Барсук всю зиму спит в норе.",
    "sable": "У соболя очень мягкий и тёплый мех.",
    "bear": "Зимой медведь спит в берлоге.",
    "yak": "Як живёт высоко в горах, ему не страшен холод.",
    "eagle": "Орёл видит маленькую мышку с большой высоты.",
    "snow_leopard": "Барс укрывается длинным хвостом, как шарфом.",
    "llama": "Лама может плюнуть, если сердится.",
    "marmot": "Сурок свистит, чтобы предупредить друзей об опасности.",
    "ram": "Бараны бодаются крепкими закрученными рогами.",
    "lion": "Рык льва слышно за несколько километров.",
    "elephant": "Слон набирает воду хоботом и пьёт.",
    "hyena": "Голос гиены похож на смех.",
    "zebra": "У каждой зебры свой узор полосок.",
    "giraffe": "Жираф — самое высокое животное на свете.",
    "rhino": "Рог носорога растёт всю жизнь.",
    "hippo": "Бегемот почти весь день сидит в воде.",
    "cobra": "Кобра раздувает капюшон, когда пугается.",
    "fennec": "Большие уши помогают фенеку не перегреться в жару.",
    "camel": "Верблюд может очень долго обходиться без воды.",
    "lizard": "Ящерица может оставить хвост и убежать, а хвост отрастёт.",
    "scorpion": "Мама-скорпион носит деток на спине.",
    "jerboa": "Тушканчик прыгает на задних лапках, как маленький кенгуру.",
    "okapi": "Окапи — родственник жирафа, хоть и похож на зебру.",
    "gorilla": "Горилла — самая большая обезьяна на свете.",
    "leopard": "Леопард затаскивает добычу высоко на дерево.",
    "chimpanzee": "Шимпанзе достают еду палочками, как инструментом.",
    "chameleon": "Хамелеон меняет цвет и смотрит глазами в разные стороны.",
    "tiger": "Тигр любит плавать и купаться.",
    "panda": "Панда почти весь день ест бамбук.",
    "python": "После большого обеда питон может долго не есть.",
    "peacock": "Павлин раскрывает хвост с узорами-глазками.",
    "macaque": "Некоторые макаки зимой греются в горячих источниках.",
    "orangutan": "Орангутан каждый вечер делает себе гнездо из веток.",
    "toucan": "Огромный клюв тукана очень лёгкий.",
    "jaguar": "Ягуар отлично плавает и ловит рыбу.",
    "tapir": "У тапира маленький хоботок, как у слонёнка.",
    "sloth": "Ленивец почти всю жизнь висит на дереве вниз головой.",
    "parrot": "Попугаи умеют повторять слова.",
    "anaconda": "Анаконда — одна из самых больших змей на свете.",
    "emu": "Эму не умеет летать, зато очень быстро бегает.",
    "koala": "Коала ест листья эвкалипта и много спит.",
    "dingo": "Динго — дикая собака Австралии.",
    "wombat": "Вомбат роет длинные норы под землёй.",
    "echidna": "Ехидна откладывает яйца, а деток кормит молоком.",
    "kangaroo": "Мама-кенгуру носит малыша в сумке на животе.",
    "platypus": "Утконос откладывает яйца, а нос у него как у утки.",
    "lemur": "Лемуры живут только на острове Мадагаскар.",
    "monitor_lizard": "Комодский варан — самая большая ящерица на свете.",
    "gecko": "Геккон бегает по стеклу и потолку и не падает.",
    "iguana": "Игуана греется на солнышке, чтобы набраться сил.",
    "pelican": "У пеликана под клювом мешок для рыбы.",
    "flamingo": "Фламинго розовые, потому что едят розовых рачков.",
    "walrus": "Морж цепляется бивнями за лёд, когда вылезает из воды.",
    "nerpa": "Нерпа живёт в озере Байкал.",
    "arctic_fox": "Зимой песец белый, а летом бурый.",
    "seal": "Тюлень может долго нырять, задержав дыхание.",
    "narwhal": "Длинный бивень нарвала — это его зуб.",
    "penguin": "Пингвины не летают, зато отлично плавают.",
    "albatross": "Альбатрос часами летит, почти не взмахивая крыльями.",
    "aurochs": "Тур — дикий предок домашних коров.",
    "bison": "Бизоны живут большими стадами и носят тёплую шубу.",
    "saiga": "Нос у сайги похож на маленький хоботок.",
    "mammoth": "Мамонт был покрыт густой шерстью и жил давным-давно.",
    "muskox": "У овцебыка шерсть такая длинная, что свисает почти до земли.",
    "crab": "Краб ходит боком.",
    "stingray": "Скат плавает, взмахивая плавниками, как крыльями.",
    "seahorse": "У морских коньков деток вынашивает папа.",
    "moray": "Мурена прячется в норках между камнями и кораллами.",
    "turtle": "Морская черепаха откладывает яйца в песок на пляже.",
    "cuttlefish": "Каракатица меняет цвет за одно мгновение.",
    "whale": "Синий кит — самое большое животное на Земле.",
    "shark": "У акулы взамен выпавших зубов растут новые.",
    "tuna": "Тунец плавает очень быстро и почти никогда не останавливается.",
    "dolphin": "Дельфины зовут друг друга свистом, как по имени.",
    "orca": "Касатки живут большими семьями и охотятся вместе.",
    "squid": "У кальмара десять щупалец.",
    "lobster": "Омар может прожить очень много лет.",
    "starfish": "Если морская звезда потеряет лучик, у неё вырастет новый.",
    "jellyfish": "Медуза почти вся состоит из воды.",
    "shrimp": "Испугавшись, креветка уплывает хвостом вперёд.",
    "octopus": "У осьминога три сердца и восемь щупалец.",
    "anglerfish": "Удильщик светит фонариком на голове и приманивает рыбок.",
    "raptor": "Раптор был покрыт перьями, как птица.",
    "diplodocus": "Диплодок был длиннее двух автобусов.",
    "stegosaurus": "На спине у стегозавра большие пластины, а на хвосте — шипы.",
    "ankylosaurus": "Анкилозавр отбивался от врагов хвостом-булавой.",
    "triceratops": "У трицератопса три рога и большой костяной воротник.",
    "tyrannosaurus": "У огромного тираннозавра были совсем маленькие передние лапки.",
    "mosasaurus": "Мозазавр — огромный морской ящер, он жил в океане.",
    "ichthyosaurus": "Ихтиозавр был похож на дельфина.",
    "plesiosaurus": "Плезиозавр плавал, загребая четырьмя ластами.",
    "pteranodon": "Птеранодон летал над морем и ловил рыбу.",
    "pterodactyl": "Птеродактиль летал на крыльях из кожи.",
}

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
# First run: the first N levels of the campaign are `tutorial` (hand demo, forgiving magnet, always 3 stars).
# They must be guaranteed joy, so their words stay short.
TUTORIAL_LEVELS = 3
TUTORIAL_MAX_WORD = 3


def color(hex_: str) -> str:
    h = hex_.lstrip("#")
    r, g, b = (int(h[i:i + 2], 16) / 255 for i in (0, 2, 4))
    return f"Color({r:.4g}, {g:.4g}, {b:.4g}, 1)"


def q(s: str) -> str:
    return '"' + s.replace("\\", "\\\\").replace('"', '\\"') + '"'


def res(path: Path) -> str:
    return "res://" + path.relative_to(ROOT).as_posix()


def write_level(level_id: int, animal_id: str, word: str, ghosts: bool, difficulty: int, tutorial: bool) -> Path:
    assert animal_id in EMOJI, f"no emoji for {animal_id}"
    assert animal_id in FACTS, f"no fact for {animal_id}"
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
        + f"fact = {q(FACTS[animal_id])}\n"
        + f"parts = PackedStringArray({parts})\n"
        + tex_line
        + f"show_ghost_hints = {'true' if ghosts else 'false'}\n"
        + ("tutorial = true\n" if tutorial else "")
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
                tutorial = total < TUTORIAL_LEVELS
                assert not tutorial or len(word) <= TUTORIAL_MAX_WORD, f"tutorial word {word} is too long"
                level_paths.append(write_level(zone_number * 100 + idx, aid, word, show_ghost, difficulty, tutorial))
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
