class_name DecorPiece
extends Control

## A park decoration glyph (on the map, in the box, or as the drag ghost).
## When `draggable`, a press starts a drag: the host moves it and decides where it lands.

signal ev_drag_started(piece: DecorPiece)
signal ev_dragged(piece: DecorPiece, global_pos: Vector2)
signal ev_dropped(piece: DecorPiece, global_pos: Vector2)

@export var glyph_label: Label
@export var draggable: bool = true

var item: DecorItem
var _dragging: bool = false


func setup(p_item: DecorItem) -> void:
	item = p_item
	glyph_label.text = item.glyph


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and (event as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT:
		var mb := event as InputEventMouseButton
		if mb.pressed:
			if draggable:
				_dragging = true
				ev_drag_started.emit(self)
			else:
				wiggle()
		elif _dragging:
			_dragging = false
			ev_dropped.emit(self, mb.global_position)
		accept_event()
	elif event is InputEventMouseMotion and _dragging:
		ev_dragged.emit(self, (event as InputEventMouseMotion).global_position)
		accept_event()


func wiggle() -> void:
	pivot_offset = size * 0.5
	var tw := create_tween()
	for a in [8.0, -6.0, 4.0, 0.0]:
		tw.tween_property(self, "rotation_degrees", a, 0.07)


func bounce() -> void:
	pivot_offset = size * Vector2(0.5, 1.0)
	var tw := create_tween()
	tw.tween_property(self, "scale", Vector2(1.2, 0.85), 0.08)
	tw.tween_property(self, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BOUNCE)
