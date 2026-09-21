class_name GameStateVictory
extends GameState

static func get_state() -> String:
	return "Victory"


func enter(_prev: FSMState, _data: Dictionary) -> void:
	if manager:
		manager.begin_victory()
