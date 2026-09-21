class_name ParentalGate
extends Control

## Simple hold-to-confirm gate (3s) so kids cannot open settings alone.

signal ev_passed
signal ev_cancelled

@export var hold_button: Button
@export var progress_bar: ProgressBar
@export var cancel_button: Button
@export var hold_seconds: float = 3.0

var _holding: bool = false
var _elapsed: float = 0.0


func _ready() -> void:
	visible = false
	mouse_filter = Control.MOUSE_FILTER_STOP
	if hold_button == null:
		hold_button = get_node_or_null("Panel/HoldButton") as Button
	if progress_bar == null:
		progress_bar = get_node_or_null("Panel/ProgressBar") as ProgressBar
	if cancel_button == null:
		cancel_button = get_node_or_null("Panel/CancelButton") as Button
	if hold_button:
		hold_button.button_down.connect(_on_hold_down)
		hold_button.button_up.connect(_on_hold_up)
	if cancel_button:
		cancel_button.pressed.connect(_on_cancel)
	if progress_bar:
		progress_bar.max_value = hold_seconds
		progress_bar.value = 0.0


func open() -> void:
	visible = true
	_holding = false
	_elapsed = 0.0
	if progress_bar:
		progress_bar.value = 0.0


func close() -> void:
	visible = false
	_holding = false


func _process(delta: float) -> void:
	if not visible or not _holding:
		return
	_elapsed += delta
	if progress_bar:
		progress_bar.value = _elapsed
	if _elapsed >= hold_seconds:
		_holding = false
		close()
		ev_passed.emit()


func _on_hold_down() -> void:
	_holding = true
	_elapsed = 0.0


func _on_hold_up() -> void:
	_holding = false
	_elapsed = 0.0
	if progress_bar:
		progress_bar.value = 0.0


func _on_cancel() -> void:
	close()
	ev_cancelled.emit()
