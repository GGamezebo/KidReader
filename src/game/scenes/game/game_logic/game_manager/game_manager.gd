class_name GameManager
extends Node

## In-level FSM: Playing → Completing → Victory

const EV_WORD_DONE := "ev.word_done"
const EV_VICTORY_READY := "ev.victory_ready"

var fsm: FSM
var level_scene: Node
var wrong_drops: int = 0


func setup(p_level_scene: Node) -> void:
	level_scene = p_level_scene
	wrong_drops = 0
	var states: Array = [
		GameStatePlaying.new(GameStatePlaying.get_state(), self),
		GameStateCompleting.new(GameStateCompleting.get_state(), self),
		GameStateVictory.new(GameStateVictory.get_state(), self),
	]
	for state in states:
		add_child(state)
	fsm = FSM.new({
		"initial": {"state": GameStatePlaying.get_state()},
		"transitions": [
			{
				"src": GameStatePlaying.get_state(),
				"dst": GameStateCompleting.get_state(),
				"event": EV_WORD_DONE,
			},
			{
				"src": GameStateCompleting.get_state(),
				"dst": GameStateVictory.get_state(),
				"event": EV_VICTORY_READY,
			},
		],
		"states": states,
	})


func deinit() -> void:
	if fsm:
		fsm.deinit()
		fsm = null
	level_scene = null


func notify_word_complete() -> void:
	if fsm and fsm.can_fire(EV_WORD_DONE):
		fsm.add_event(EV_WORD_DONE)


func begin_play() -> void:
	if level_scene and level_scene.has_method("on_fsm_playing"):
		level_scene.on_fsm_playing()


func begin_completing() -> void:
	_run_completing()


func begin_victory() -> void:
	if level_scene and level_scene.has_method("on_fsm_victory"):
		level_scene.on_fsm_victory(calc_stars())


func calc_stars() -> int:
	if wrong_drops <= 0:
		return 3
	if wrong_drops <= 2:
		return 2
	return 1


func _run_completing() -> void:
	if level_scene and level_scene.has_method("play_completion_sequence"):
		await level_scene.play_completion_sequence()
	if fsm and fsm.can_fire(EV_VICTORY_READY):
		fsm.add_event(EV_VICTORY_READY)
