class_name GameStateCompleting
extends GameState

static func get_state() -> String:
	return "Completing"


func enter(_prev: FSMState, _data: Dictionary) -> void:
	if manager:
		manager.begin_completing()
