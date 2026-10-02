class_name RoundDot
extends Panel

## Festival progress dot: TODO (number), NOW (green ring), DONE (gold paw).

enum State { TODO, NOW, DONE }

@export var label: Label
@export var todo_style: StyleBox
@export var now_style: StyleBox
@export var done_style: StyleBox


func setup(number: int, state: State) -> void:
	label.text = "🐾" if state == State.DONE else str(number)
	var style := todo_style
	if state == State.NOW:
		style = now_style
	elif state == State.DONE:
		style = done_style
	add_theme_stylebox_override("panel", style)
