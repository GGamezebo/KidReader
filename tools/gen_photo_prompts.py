# -*- coding: utf-8 -*-
"""Write image-generation prompts for every animal of the zoo table (tools/gen_zoo_content.py).

Run from project root (plain Python 3, no deps):
    python tools/gen_photo_prompts.py          # only animals without a photo yet
    python tools/gen_photo_prompts.py --all    # every animal

Writes:
    concepts/photo_prompts.md   human list: zone → animal → prompt (copy-paste into any image AI)
    concepts/photo_prompts.csv  file_name;prompt (for batch tools)

Save each generated picture as tools/photo_inbox/<animal_id>.<png|jpg|webp> and run
tools/import_photos.py — it crops to 16:9, writes assets/animals/animal_<id>.jpg and regenerates levels.
"""
from __future__ import annotations

import sys
from pathlib import Path

from gen_zoo_content import PHOTOS, REGIONS, ROOT

OUT_MD = ROOT / "concepts" / "photo_prompts.md"
OUT_CSV = ROOT / "concepts" / "photo_prompts.csv"

# Shared look: matches the existing photos (bright natural daylight, whole animal, centred, soft background).
STYLE = (
    "realistic wildlife photograph, {subject}, {scene}. The whole animal is fully visible, centred, "
    "facing the camera at three-quarter angle, friendly calm expression, eyes visible. "
    "Subject fits inside the central square of the frame with space around it. "
    "Bright soft daylight, vivid natural colours, shallow depth of field, sharp focus on the animal, "
    "background simple and uncluttered. Landscape 16:9. "
    "No people, no text, no watermark, no frame, no other animals, nothing scary."
)
DINO_STYLE = (
    "photorealistic nature-documentary image of a {subject}, {scene}. The whole dinosaur is fully visible, "
    "centred, standing calmly, gentle friendly look, mouth closed, eyes visible, accurate modern "
    "paleontology look. Subject fits inside the central square of the frame with space around it. "
    "Bright warm daylight, vivid natural colours, sharp focus, simple uncluttered background. Landscape 16:9. "
    "No people, no text, no watermark, no blood, no fighting, nothing scary — suitable for a 5-year-old."
)
UNDERWATER = "underwater photograph, clear turquoise water, sun rays from above"

# Zone → background scene.
SCENES = {
    "farm": "on a sunny green farmyard with a wooden fence",
    "forest": "in a sunlit summer forest clearing",
    "pond": "at a calm pond with reeds and green bank",
    "poultry": "in a sunny village poultry yard with straw",
    "meadow": "macro photo, on a flower in a blooming summer meadow",
    "taiga": "in a sunlit taiga forest with pines and moss",
    "mountains": "on a green mountain slope with snowy peaks far behind",
    "savanna": "in the golden African savanna with acacia trees",
    "desert": "on warm sand dunes in a sunny desert",
    "africa_forest": "in a lush green African rainforest",
    "asia": "in a green Asian forest with bamboo",
    "amazon": "in the lush Amazon jungle",
    "australia": "in the sunny Australian bush with eucalyptus trees",
    "islands": "on a tropical island with palms and blue lagoon",
    "ice": "on white Arctic ice and snow under a blue sky",
    "ice_age": "on a snowy Ice Age steppe with distant glaciers",
    "reef": f"{UNDERWATER}, colourful coral reef",
    "ocean": f"{UNDERWATER}, open blue ocean",
    "deep_sea": f"{UNDERWATER}, dark blue deep sea softly lit",
    "dino_valley": "in a prehistoric valley with ferns, cycads and a volcano far away",
    "dino_sea_sky": "in a prehistoric world with ferns, sea and cliffs",
}
DINO_ZONES = {"dino_valley", "dino_sea_sky"}

# animal_id → English subject (add detail where a model may guess wrong).
SUBJECTS = {
    "cat": "a fluffy ginger domestic cat", "dog": "a friendly golden domestic dog",
    "bull": "a brown bull with short horns", "goat": "a white domestic goat",
    "horse": "a chestnut horse", "sheep": "a fluffy white sheep",
    "hedgehog": "a European hedgehog", "fox": "a red fox", "owl": "a tawny owl sitting on a branch",
    "wolf": "a grey wolf", "moose": "a moose (elk) with antlers", "deer": "a red deer with antlers",
    "squirrel": "a red squirrel on a branch",
    "crayfish": "a freshwater crayfish on a pebble at the water's edge", "frog": "a green frog on a lily pad",
    "fish": "a carp fish swimming just under clear water, seen from the side",
    "beaver": "a beaver on the bank", "heron": "a grey heron standing in shallow water",
    "swan": "a white mute swan on the water",
    "goose": "a white domestic goose", "duck": "a mallard duck", "turkey": "a domestic turkey with fanned tail",
    "rooster": "a colourful rooster", "hen": "a brown hen", "pigeon": "a grey rock pigeon",
    "beetle": "a shiny stag beetle", "wasp": "a wasp", "fly": "a housefly",
    "bee": "a honey bee", "mosquito": "a mosquito", "snail": "a garden snail with spiral shell",
    "butterfly": "a bright swallowtail butterfly with open wings",
    "lynx": "a Eurasian lynx with ear tufts", "hare": "a brown hare", "boar": "a wild boar",
    "badger": "a European badger", "sable": "a dark brown sable", "bear": "a brown bear",
    "yak": "a shaggy yak", "eagle": "a golden eagle perched on a rock",
    "snow_leopard": "a snow leopard", "llama": "a white llama", "marmot": "a marmot standing on its hind legs",
    "ram": "a bighorn ram with curled horns",
    "lion": "a male lion with a mane", "elephant": "an African elephant", "hyena": "a spotted hyena",
    "zebra": "a zebra", "giraffe": "a giraffe", "rhino": "a white rhinoceros", "hippo": "a hippopotamus at a river bank",
    "cobra": "a cobra with its hood spread, calm", "fennec": "a fennec fox with big ears",
    "camel": "a two-humped camel", "lizard": "a sand lizard on a rock", "scorpion": "a desert scorpion",
    "jerboa": "a jerboa with long hind legs and tufted tail",
    "okapi": "an okapi", "gorilla": "a mountain gorilla sitting", "leopard": "a leopard",
    "chimpanzee": "a young chimpanzee", "chameleon": "a green chameleon on a branch",
    "tiger": "a Bengal tiger", "panda": "a giant panda eating bamboo", "python": "a python coiled on a branch",
    "peacock": "a peacock with its tail fanned", "macaque": "a macaque monkey", "orangutan": "an orangutan",
    "toucan": "a toucan on a branch", "jaguar": "a jaguar", "tapir": "a South American tapir",
    "sloth": "a three-toed sloth hanging on a branch", "parrot": "a scarlet macaw parrot",
    "anaconda": "a green anaconda by the river",
    "emu": "an emu", "koala": "a koala in a eucalyptus tree", "dingo": "a dingo", "wombat": "a wombat",
    "echidna": "a short-beaked echidna", "kangaroo": "a red kangaroo", "platypus": "a platypus at a creek bank",
    "lemur": "a ring-tailed lemur", "monitor_lizard": "a Komodo dragon monitor lizard",
    "gecko": "a bright green day gecko", "iguana": "a green iguana", "pelican": "a white pelican",
    "flamingo": "a pink flamingo standing in shallow water",
    "walrus": "a walrus with tusks", "nerpa": "a Baikal seal (nerpa) on ice", "arctic_fox": "a white arctic fox",
    "seal": "a harbour seal", "narwhal": "a narwhal with its long tusk at the ice edge in water",
    "penguin": "an emperor penguin", "albatross": "an albatross",
    "aurochs": "an aurochs, the wild ancestral bull with long forward horns",
    "bison": "a European bison", "saiga": "a saiga antelope with its big nose",
    "mammoth": "a woolly mammoth (realistic reconstruction)", "muskox": "a muskox",
    "crab": "a red crab on the sandy sea floor", "stingray": "a stingray gliding over sand",
    "seahorse": "a yellow seahorse", "moray": "a moray eel peeking from coral, calm",
    "turtle": "a green sea turtle swimming", "cuttlefish": "a cuttlefish",
    "whale": "a humpback whale", "shark": "a whale shark (gentle)", "tuna": "a bluefin tuna",
    "dolphin": "a smiling bottlenose dolphin", "orca": "an orca killer whale",
    "squid": "a squid",
    "lobster": "a blue-orange lobster on the sea floor", "starfish": "an orange starfish on the sea floor",
    "jellyfish": "a glowing translucent jellyfish", "shrimp": "a red shrimp",
    "octopus": "an orange octopus", "anglerfish": "a deep-sea anglerfish with its glowing lure, cute not scary",
    "raptor": "a feathered velociraptor dinosaur", "diplodocus": "a long-necked diplodocus dinosaur",
    "stegosaurus": "a stegosaurus dinosaur with back plates", "ankylosaurus": "an armoured ankylosaurus dinosaur with tail club",
    "triceratops": "a triceratops dinosaur with three horns", "tyrannosaurus": "a tyrannosaurus rex dinosaur",
    "mosasaurus": "a mosasaurus marine reptile swimming underwater",
    "ichthyosaurus": "a dolphin-like ichthyosaurus swimming underwater",
    "plesiosaurus": "a long-necked plesiosaurus swimming in the sea",
    "pteranodon": "a pteranodon flying over the sea", "pterodactyl": "a small pterodactyl perched on a cliff",
}


def prompt_for(zone_id: str, animal_id: str) -> str:
    style = DINO_STYLE if zone_id in DINO_ZONES else STYLE
    return style.format(subject=SUBJECTS[animal_id], scene=SCENES[zone_id])


def main() -> None:
    every = "--all" in sys.argv
    md = ["# Animal photo prompts", "",
          "Generated by `tools/gen_photo_prompts.py`. Save each picture as "
          "`tools/photo_inbox/<animal_id>.png` (or .jpg/.webp), then run `python tools/import_photos.py`.", ""]
    csv = ["file_name;prompt"]
    count = 0
    for (_rid, rname, *_rest, zones) in REGIONS:
        md += [f"## {rname}", ""]
        for (zid, zname, zicon, _color, animals) in zones:
            assert zid in SCENES, f"no scene for zone {zid}"
            rows = []
            for aid, word in animals:
                assert aid in SUBJECTS, f"no subject for {aid}"
                if not every and (PHOTOS / f"animal_{aid}.jpg").exists():
                    continue
                p = prompt_for(zid, aid)
                rows += [f"**{word}** → `{aid}.png`", "", "```", p, "```", ""]
                csv.append(f"{aid}.png;{p}")
                count += 1
            if rows:
                md += [f"### {zicon} {zname}", ""] + rows
    OUT_MD.write_text("\n".join(md), encoding="utf-8")
    OUT_CSV.write_text("\n".join(csv) + "\n", encoding="utf-8")
    print(f"{count} prompts -> {OUT_MD.relative_to(ROOT)}, {OUT_CSV.relative_to(ROOT)}")


if __name__ == "__main__":
    main()
