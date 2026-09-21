class_name GameState
extends FSMState

var manager: GameManager


func _init(p_name: String, p_manager: GameManager) -> void:
	super._init(p_name)
	manager = p_manager
