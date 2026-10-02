class_name DragScroll
extends Node

## Mouse drag-to-scroll for a ScrollContainer (horizontal, or vertical) on desktop/web
## (on touchscreens ScrollContainer already drags natively, so this stays idle).
## A drag longer than `threshold` swallows the release so buttons under the cursor don't fire.

@export var scroll: ScrollContainer
@export var threshold: float = 14.0
@export var vertical: bool = false
## Set by the host while something else is being dragged (e.g. a map decoration).
var suspended: bool = false

var _pressed: bool = false
var _dragging: bool = false
var _travel: float = 0.0


func _input(event: InputEvent) -> void:
	if scroll == null or not scroll.is_visible_in_tree() or DisplayServer.is_touchscreen_available():
		return
	if event is InputEventMouseButton and (event as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT:
		var mb := event as InputEventMouseButton
		if mb.pressed:
			_pressed = scroll.get_global_rect().has_point(mb.position)
			_dragging = false
			_travel = 0.0
		else:
			if _dragging:
				get_viewport().set_input_as_handled()
			_pressed = false
			_dragging = false
	elif event is InputEventMouseMotion and _pressed and not suspended:
		var rel := (event as InputEventMouseMotion).relative
		var d := rel.y if vertical else rel.x
		_travel += absf(d)
		if _travel > threshold:
			_dragging = true
		if _dragging:
			if vertical:
				scroll.scroll_vertical -= int(d)
			else:
				scroll.scroll_horizontal -= int(d)
