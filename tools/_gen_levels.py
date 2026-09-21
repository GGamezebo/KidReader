from pathlib import Path

root = Path(r"d:\Godot\MyProjects\KidReader\src\levels")
root.mkdir(parents=True, exist_ok=True)
levels = [
    (1, "bull", "Бык", "БЫК", list("БЫК"), True, 1),
    (2, "cat", "Кот", "КОТ", list("КОТ"), True, 1),
    (3, "dog", "Пёс", "ПЁС", list("ПЁС"), True, 1),
    (4, "fox", "Лис", "ЛИС", list("ЛИС"), True, 1),
    (5, "lion", "Лев", "ЛЕВ", list("ЛЕВ"), True, 2),
    (6, "owl", "Сова", "СОВА", list("СОВА"), True, 2),
    (7, "duck", "Утка", "УТКА", list("УТКА"), True, 2),
    (8, "frog", "Жаба", "ЖАБА", list("ЖАБА"), False, 2),
    (9, "fish", "Рыба", "РЫБА", list("РЫБА"), False, 2),
    (10, "hedgehog", "Ёжик", "ЁЖИК", list("ЁЖИК"), False, 3),
    (11, "panda", "Панда", "ПАНДА", list("ПАНДА"), False, 3),
    (12, "deer", "Олень", "ОЛЕНЬ", list("ОЛЕНЬ"), False, 3),
]
script = "res://src/common/level_data.gd"
for lid, aid, aname, word, parts, ghost, diff in levels:
    parts_s = ", ".join(f'"{p}"' for p in parts)
    text = f"""[gd_resource type="Resource" script_class="LevelData" load_steps=2 format=3]

[ext_resource type="Script" path="{script}" id="1"]

[resource]
script = ExtResource("1")
level_id = {lid}
animal_id = "{aid}"
animal_display_name = "{aname}"
word = "{word}"
parts = PackedStringArray({parts_s})
show_ghost_hints = {str(ghost).lower()}
difficulty = {diff}
"""
    (root / f"level_{lid}.tres").write_text(text, encoding="utf-8")
print("wrote", len(levels))
