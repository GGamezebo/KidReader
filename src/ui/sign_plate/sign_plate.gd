@tool
class_name SignPlate
extends PanelContainer

## Wooden sign with a word in red letters (same glyph color as letter tiles). Blank = «? ? ?» placeholder.

@export var word: String = "СЛОВО":
	set(v):
		word = v
		_refresh()
@export var blank: bool = false:
	set(v):
		blank = v
		_refresh()
## Font for words up to `fit_letters`; longer words scale down to keep the sign narrow.
@export var font_size: int = 30:
	set(v):
		font_size = v
		_refresh()
@export var fit_letters: int = 6
@export var word_color: Color = Color("E53935")
@export var blank_color: Color = Color(1, 1, 1, 0.75)
@export var label: Label


func _ready() -> void:
	_refresh()


func setup(p_word: String, p_blank: bool = false) -> void:
	word = p_word
	blank = p_blank


func _refresh() -> void:
	if label == null:
		return
	label.text = "?".repeat(word.length()) if blank else word
	label.add_theme_color_override("font_color", blank_color if blank else word_color)
	var n := maxi(word.length(), 1)
	label.add_theme_font_size_override("font_size", font_size if n <= fit_letters else int(font_size * fit_letters / float(n)))
