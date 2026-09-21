class_name WordSlot
extends Control

signal ev_filled(slot: WordSlot, tile: LetterTile)
signal ev_tapped(slot: WordSlot)

@export var label: Label
@export var panel: Panel
@export var ghost_label: Label

var slot_index: int = 0
var expected: String = ""
var filled: bool = false
var show_ghost: bool = true
var _pulse_tween: Tween


func _ready() -> void:
	custom_minimum_size = Vector2(100, 100)
	size = Vector2(100, 100)
	mouse_filter = Control.MOUSE_FILTER_STOP
	if panel == null:
		panel = get_node_or_null("Panel") as Panel
	if label == null:
		label = get_node_or_null("Panel/Label") as Label
	if ghost_label == null:
		ghost_label = get_node_or_null("Panel/Ghost") as Label
	_apply_style(false)
	_refresh_labels()


func _gui_input(event: InputEvent) -> void:
	if not filled:
		return
	if event is InputEventScreenTouch and (event as InputEventScreenTouch).pressed:
		ev_tapped.emit(self)
		accept_event()
	elif event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
			ev_tapped.emit(self)
			accept_event()


func setup(index: int, part: String, p_show_ghost: bool, prefilled: bool) -> void:
	slot_index = index
	expected = part
	show_ghost = p_show_ghost
	if prefilled:
		filled = true
		if label:
			label.text = part
			label.add_theme_color_override("font_color", Color("E53935"))
		if ghost_label:
			ghost_label.visible = false
		_apply_style(true)
	else:
		filled = false
		_refresh_labels()
		_apply_style(false)


func _refresh_labels() -> void:
	if label:
		label.text = ""
	if ghost_label:
		ghost_label.text = expected if show_ghost else ""
		ghost_label.visible = show_ghost and not filled
		ghost_label.add_theme_color_override("font_color", Color(1, 1, 1, 0.55))
		ghost_label.add_theme_font_size_override("font_size", 64)
	if label:
		label.add_theme_font_size_override("font_size", 64)
		label.add_theme_color_override("font_color", Color("E53935"))


func accepts(part: String) -> bool:
	return not filled and part == expected


func highlight(on: bool) -> void:
	if filled:
		return
	if _pulse_tween:
		_pulse_tween.kill()
		_pulse_tween = null
	if on:
		_apply_style(false, true)
		_pulse_tween = create_tween().set_loops()
		_pulse_tween.tween_property(panel, "modulate", Color(1.2, 1.15, 0.85), 0.3)
		_pulse_tween.tween_property(panel, "modulate", Color.WHITE, 0.3)
	else:
		if panel:
			panel.modulate = Color.WHITE
		_apply_style(false, false)


func place_tile(tile: LetterTile) -> void:
	filled = true
	highlight(false)
	if ghost_label:
		ghost_label.visible = false
	if label:
		label.text = ""
	_apply_style(true)
	var gpos := tile.global_position
	if tile.get_parent() != self:
		tile.reparent(self)
		tile.global_position = gpos
	var target := global_position + (size - tile.size) * 0.5
	tile.snap_to(target)
	ev_filled.emit(self, tile)


func flash() -> void:
	var tw := create_tween()
	tw.tween_property(self, "modulate", Color("FFC94A"), 0.12)
	tw.tween_property(self, "modulate", Color.WHITE, 0.18)


func _apply_style(success: bool, magnet: bool = false) -> void:
	if panel == null:
		return
	var sb := StyleBoxFlat.new()
	if success:
		sb.bg_color = Color(0.45, 0.78, 0.42, 0.55)
		sb.border_color = Color(0.35, 0.65, 0.32, 0.9)
	elif magnet:
		sb.bg_color = Color(0.95, 0.88, 0.35, 0.45)
		sb.border_color = Color(1.0, 0.92, 0.35, 0.95)
	else:
		sb.bg_color = Color(0.55, 0.58, 0.6, 0.35)
		sb.border_color = Color(0.85, 0.88, 0.9, 0.55)
	sb.set_corner_radius_all(20)
	sb.set_border_width_all(3)
	panel.add_theme_stylebox_override("panel", sb)
