class_name ParentCorner
extends Control

## Parent corner (overlay behind the ParentalGate): progress, play time, hard letters, audio, reset.
## Text is for adults, so labels are fine here. Data comes in via open(stats) — see
## ProgressController.get_parent_stats(); the host (menu) handles the signals.

signal ev_toggle_music
signal ev_toggle_sfx
signal ev_reset_confirmed

## Template for one hard-letter chip (a SignPlate).
@export var letter_scene: PackedScene
## Second press within this time confirms the reset.
@export var reset_confirm_time: float = 4.0
@export var reset_text: String = "Сбросить прогресс"
@export var reset_confirm_text: String = "Точно? Нажмите ещё раз"

@export_group("Nodes")
@export var panel: Control
@export var dim: BaseButton
@export var close_button: BaseButton
@export var animals_value: Label
@export var festivals_value: Label
@export var today_value: Label
@export var total_value: Label
@export var letters_row: HFlowContainer
@export var letters_empty: Control
@export var music_toggle: Button
@export var sfx_toggle: Button
@export var reset_button: Button

var _reset_armed: bool = false
var _reset_timer: SceneTreeTimer


func _ready() -> void:
	visible = false
	dim.pressed.connect(close)
	close_button.pressed.connect(close)
	music_toggle.pressed.connect(func(): ev_toggle_music.emit())
	sfx_toggle.pressed.connect(func(): ev_toggle_sfx.emit())
	reset_button.pressed.connect(_on_reset_pressed)


func open(stats: Dictionary) -> void:
	visible = true
	_disarm_reset()
	animals_value.text = "%d / %d" % [int(stats.get("animals", 0)), int(stats.get("animals_total", 0))]
	festivals_value.text = "%d / %d" % [int(stats.get("festivals", 0)), int(stats.get("zones_total", 0))]
	today_value.text = format_duration(int(stats.get("today_seconds", 0)))
	total_value.text = format_duration(int(stats.get("total_seconds", 0)))
	for child in letters_row.get_children():
		child.queue_free()
	var letters: Array = stats.get("hard_letters", [])
	letters_empty.visible = letters.is_empty()
	for letter in letters:
		var chip := letter_scene.instantiate() as SignPlate
		letters_row.add_child(chip)
		chip.setup(str(letter))
	panel.pivot_offset = panel.size * 0.5
	panel.scale = Vector2(0.85, 0.85)
	create_tween().tween_property(panel, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func close() -> void:
	visible = false
	_disarm_reset()


func set_audio(music_muted: bool, sfx_muted: bool) -> void:
	music_toggle.text = "🔇" if music_muted else "🎵"
	sfx_toggle.text = "🔕" if sfx_muted else "🔊"


static func format_duration(seconds: int) -> String:
	var minutes := floori(seconds / 60.0)
	if minutes < 1:
		return "меньше минуты"
	if minutes < 60:
		return "%d мин" % minutes
	return "%d ч %d мин" % [floori(minutes / 60.0), minutes % 60]


func _on_reset_pressed() -> void:
	if _reset_armed:
		_disarm_reset()
		ev_reset_confirmed.emit()
		close()
		return
	_reset_armed = true
	reset_button.text = reset_confirm_text
	_reset_timer = get_tree().create_timer(reset_confirm_time)
	var timer := _reset_timer
	timer.timeout.connect(func():
		if timer == _reset_timer:
			_disarm_reset())


func _disarm_reset() -> void:
	_reset_armed = false
	_reset_timer = null
	reset_button.text = reset_text
