class_name LetterTile
extends Control

## Glass letter tile: scatters rotated, straightens on grab, magnet or fly-up on drop.

signal ev_picked(tile: LetterTile)
signal ev_dropped(tile: LetterTile, global_pos: Vector2)
signal ev_drag_moved(tile: LetterTile, global_pos: Vector2)

@export var label: Label
@export var panel: Panel

var part: String = ""
var locked: bool = false
var is_dragging: bool = false
var _drag_offset: Vector2 = Vector2.ZERO
var _base_scale: Vector2 = Vector2.ONE
var _hint_tween: Tween
var _float_tween: Tween
var _scatter_rot: float = 0.0
var cell_size: float = 100.0


func _ready() -> void:
	custom_minimum_size = Vector2(cell_size, cell_size)
	size = custom_minimum_size
	mouse_filter = Control.MOUSE_FILTER_STOP
	set_process(false)
	pivot_offset = size * 0.5
	_base_scale = Vector2.ONE
	if panel == null:
		panel = get_node_or_null("Panel") as Panel
	if label == null:
		label = get_node_or_null("Panel/Label") as Label
	_apply_style(false)


func setup(p_part: String) -> void:
	part = p_part
	if label:
		label.text = part
		label.add_theme_color_override("font_color", Color("E53935"))
		label.add_theme_font_size_override("font_size", _font_size())


## Square cell side in px; long words shrink cells so the whole word fits on one row.
func set_cell_size(px: float) -> void:
	cell_size = px
	custom_minimum_size = Vector2(px, px)
	size = custom_minimum_size
	pivot_offset = size * 0.5
	for l in [label]:
		if l:
			l.add_theme_font_size_override("font_size", _font_size())


func _font_size() -> int:
	return roundi(64.0 * cell_size / 100.0)


func scatter_pose(rot_deg: float) -> void:
	_scatter_rot = rot_deg
	rotation_degrees = rot_deg
	_start_float()


func _start_float() -> void:
	stop_float()
	if locked:
		return
	_float_tween = create_tween().set_loops()
	var amp := randf_range(6.0, 14.0)
	var base := position
	_float_tween.tween_property(self, "position:y", base.y - amp, randf_range(0.7, 1.2)).set_trans(Tween.TRANS_SINE)
	_float_tween.tween_property(self, "position:y", base.y + amp * 0.5, randf_range(0.7, 1.2)).set_trans(Tween.TRANS_SINE)


func stop_float() -> void:
	if _float_tween:
		_float_tween.kill()
		_float_tween = null


func _gui_input(event: InputEvent) -> void:
	if locked:
		return
	if event is InputEventScreenTouch:
		var st := event as InputEventScreenTouch
		if st.pressed:
			_begin_drag(_to_global(st.position))
		else:
			_end_drag()
		accept_event()
	elif event is InputEventScreenDrag:
		var sd := event as InputEventScreenDrag
		if is_dragging:
			_move_drag(_to_global(sd.position))
			accept_event()
	elif event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT:
			if mb.pressed:
				_begin_drag(mb.global_position)
			else:
				_end_drag()
			accept_event()
	elif event is InputEventMouseMotion and is_dragging:
		var mm := event as InputEventMouseMotion
		_move_drag(mm.global_position)
		accept_event()


func _to_global(local_pos: Vector2) -> Vector2:
	return get_global_transform_with_canvas() * local_pos


func _begin_drag(global_pos: Vector2) -> void:
	is_dragging = true
	stop_float()
	stop_hint()
	_drag_offset = global_pos - global_position
	z_index = 50
	var keep := global_position
	top_level = true
	global_position = keep
	set_process(true)
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(self, "rotation_degrees", 0.0, 0.12)
	tw.tween_property(self, "scale", _base_scale * 1.14, 0.1)
	ev_picked.emit(self)


func _process(_delta: float) -> void:
	if not is_dragging:
		return
	global_position = get_global_mouse_position() - _drag_offset
	ev_drag_moved.emit(self, global_position + size * 0.5)


func _move_drag(global_pos: Vector2) -> void:
	global_position = global_pos - _drag_offset
	ev_drag_moved.emit(self, global_position + size * 0.5)


func _end_drag() -> void:
	if not is_dragging:
		return
	is_dragging = false
	set_process(false)
	z_index = 0
	var tw := create_tween()
	tw.tween_property(self, "scale", _base_scale, 0.08)
	ev_dropped.emit(self, global_position + size * 0.5)


func snap_to(global_target: Vector2) -> void:
	locked = true
	stop_float()
	stop_hint()
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	top_level = true
	var tw := create_tween()
	tw.set_parallel(true)
	tw.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(self, "global_position", global_target, 0.2)
	tw.tween_property(self, "rotation_degrees", 0.0, 0.12)
	tw.tween_property(self, "scale", _base_scale, 0.12)
	_apply_style(true)


func fly_up_repel(viewport_size: Vector2) -> void:
	## Released too low / not snapped — force flings the tile upward.
	stop_float()
	var target_x := clampf(global_position.x + randf_range(-180.0, 180.0), 24.0, viewport_size.x - size.x - 24.0)
	var target_y := randf_range(viewport_size.y * 0.12, viewport_size.y * 0.42)
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(self, "global_position", Vector2(target_x, target_y), 0.45).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(self, "rotation_degrees", randf_range(-28.0, 28.0), 0.35)
	tw.chain().tween_callback(func():
		if is_instance_valid(self) and not locked:
			_start_float()
	)


func play_hint() -> void:
	stop_hint()
	_hint_tween = create_tween().set_loops()
	_hint_tween.tween_property(self, "scale", _base_scale * 1.1, 0.35)
	_hint_tween.tween_property(self, "scale", _base_scale, 0.35)


func stop_hint() -> void:
	if _hint_tween:
		_hint_tween.kill()
		_hint_tween = null
	if not is_dragging:
		scale = _base_scale


func _apply_style(success: bool) -> void:
	if panel == null:
		return
	var sb := StyleBoxFlat.new()
	if success:
		sb.bg_color = Color(0.45, 0.78, 0.42, 0.92)
		sb.border_color = Color(0.35, 0.65, 0.32, 1)
	else:
		sb.bg_color = Color(0.55, 0.78, 0.95, 0.55)
		sb.border_color = Color(0.75, 0.9, 1.0, 0.85)
	sb.set_corner_radius_all(22)
	sb.set_border_width_all(3)
	sb.shadow_color = Color(0, 0, 0, 0.2)
	sb.shadow_size = 8
	sb.shadow_offset = Vector2(0, 3)
	panel.add_theme_stylebox_override("panel", sb)
