class_name IconButton
extends Button

## Large finger-friendly icon button (glyph text, no chrome labels).

@export var glyph: String = "🏠":
	set(v):
		glyph = v
		text = v


func _ready() -> void:
	custom_minimum_size = Vector2(88, 88)
	text = glyph
	focus_mode = Control.FOCUS_NONE
