class_name GameStatePlaying
extends GameState

static func get_state() -> String:
	return "Playing"


func enter(_prev: FSMState, _data: Dictionary) -> void:
	if manager:
		manager.begin_play()
