# -*- coding: utf-8 -*-
from pathlib import Path

root = Path(r"d:\Godot\MyProjects\KidReader")
levels = [
    dict(id=1, animal="bunny", name="Зайчик", word="МАМА", parts=["МА", "МА"], distractors=["ПА", "ЛА"], revealed=[0], ghost=True, diff=1),
    dict(id=2, animal="cat", name="Котик", word="КОТ", parts=["К", "О", "Т"], distractors=["М", "П"], revealed=[1], ghost=True, diff=1),
    dict(id=3, animal="dog", name="Пёсик", word="ДОМ", parts=["ДО", "М"], distractors=["ТО", "НА"], revealed=[], ghost=True, diff=1),
    dict(id=4, animal="duck", name="Уточка", word="УТКА", parts=["У", "ТКА"], distractors=["А", "КА"], revealed=[], ghost=True, diff=1),
    dict(id=5, animal="fox", name="Лисичка", word="ЛИСА", parts=["ЛИ", "СА"], distractors=["ЛА", "СИ"], revealed=[], ghost=True, diff=2),
    dict(id=6, animal="frog", name="Лягушка", word="ЛЯГУШКА", parts=["ЛЯ", "ГУ", "ШКА"], distractors=["ЛУ", "ГА"], revealed=[], ghost=True, diff=2),
    dict(id=7, animal="bear", name="Мишка", word="МИШКА", parts=["МИ", "ШКА"], distractors=["МА", "ШИ"], revealed=[], ghost=True, diff=2),
    dict(id=8, animal="owl", name="Совушка", word="СОВА", parts=["СО", "ВА"], distractors=["СА", "ВО"], revealed=[], ghost=False, diff=2),
    dict(id=9, animal="panda", name="Панда", word="ПАНДА", parts=["ПАН", "ДА"], distractors=["ПА", "НА"], revealed=[], ghost=False, diff=2),
    dict(id=10, animal="lion", name="Львёнок", word="ЛЕВ", parts=["Л", "Е", "В"], distractors=["М", "Н", "Б"], revealed=[], ghost=False, diff=3),
    dict(id=11, animal="penguin", name="Пингвин", word="РЫБА", parts=["РЫ", "БА"], distractors=["РА", "БИ"], revealed=[], ghost=False, diff=3),
    dict(id=12, animal="hedgehog", name="Ёжик", word="КОРОВА", parts=["КО", "РО", "ВА"], distractors=["КА", "РА", "ВО"], revealed=[], ghost=False, diff=3),
]

lvl_dir = root / "src" / "levels"
lvl_dir.mkdir(parents=True, exist_ok=True)

for L in levels:
    parts = ", ".join(f'"{p}"' for p in L["parts"])
    dist = ", ".join(f'"{p}"' for p in L["distractors"])
    rev = ", ".join(str(i) for i in L["revealed"])
    text = f"""[gd_resource type="Resource" script_class="LevelData" load_steps=2 format=3]

[ext_resource type="Script" path="res://src/common/level_data.gd" id="1_script"]

[resource]
script = ExtResource("1_script")
level_id = {L['id']}
animal_id = "{L['animal']}"
animal_display_name = "{L['name']}"
word = "{L['word']}"
parts = PackedStringArray({parts})
distractors = PackedStringArray({dist})
revealed_indices = PackedInt32Array({rev})
show_ghost_hints = {str(L['ghost']).lower()}
difficulty = {L['diff']}
"""
    (lvl_dir / f"level_{L['id']}.tres").write_text(text, encoding="utf-8")

catalog = f'[gd_resource type="Resource" script_class="LevelsCatalog" load_steps={len(levels)+2} format=3]\n\n'
for L in levels:
    catalog += f'[ext_resource type="Resource" path="res://src/levels/level_{L["id"]}.tres" id="lvl_{L["id"]}"]\n'
catalog += '[ext_resource type="Script" path="res://src/common/levels_catalog.gd" id="1_script"]\n\n'
catalog += '[resource]\nscript = ExtResource("1_script")\n'
catalog += "levels = [" + ", ".join(f'ExtResource("lvl_{L["id"]}")' for L in levels) + "]\n"
(root / "src" / "common" / "levels_catalog.tres").write_text(catalog, encoding="utf-8")
print("ok", len(levels))
