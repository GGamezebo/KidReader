class_name DevPanel
extends Control

## Developer cheats (🛠️ at the right edge). Exists only when run from the editor — removed in exported builds.
## Emits ev_action(name); the host (menu) performs it through ProgressController.
## Actions: unlock_all, next_animal, fill_zone, pass_festival, all_miss, reset.

signal ev_action(action: String)

@export var toggle_button: BaseButton
@export var panel: Control
@export var unlock_all: BaseButton
@export var next_animal: BaseButton
@export var fill_zone: BaseButton
@export var pass_festival: BaseButton
@export var all_miss: BaseButton
@export var reset: BaseButton


func _ready() -> void:
	if not Platform.is_editor():
		queue_free()
		return
	panel.visible = false
	toggle_button.pressed.connect(func(): panel.visible = not panel.visible)
	_bind(unlock_all, "unlock_all")
	_bind(next_animal, "next_animal")
	_bind(fill_zone, "fill_zone")
	_bind(pass_festival, "pass_festival")
	_bind(all_miss, "all_miss")
	_bind(reset, "reset")


func _bind(button: BaseButton, action: String) -> void:
	button.pressed.connect(func():
		panel.visible = false
		ev_action.emit(action))
