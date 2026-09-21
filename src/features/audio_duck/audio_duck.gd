class_name AudioDuck
extends Node

## Lowers Music bus while Voice/SFX phonemes play.

@export var duck_db: float = -12.0
@export var duck_time: float = 0.08
@export var restore_time: float = 0.35
@export var hold_sec: float = 0.35

var _music_idx: int = -1
var _base_db: float = 0.0
var _tween: Tween
var _hold_timer: Timer


func _ready() -> void:
	_music_idx = AudioServer.get_bus_index("Music")
	if _music_idx >= 0:
		_base_db = AudioServer.get_bus_volume_db(_music_idx)
	_hold_timer = Timer.new()
	_hold_timer.one_shot = true
	_hold_timer.timeout.connect(_restore)
	add_child(_hold_timer)


func duck(duration_hint: float = -1.0) -> void:
	if _music_idx < 0:
		return
	if _tween:
		_tween.kill()
	_tween = create_tween()
	_tween.tween_method(_set_music_db, AudioServer.get_bus_volume_db(_music_idx), duck_db, duck_time)
	var hold := hold_sec if duration_hint < 0.0 else duration_hint
	_hold_timer.start(hold)


func _restore() -> void:
	if _music_idx < 0:
		return
	if _tween:
		_tween.kill()
	_tween = create_tween()
	_tween.tween_method(_set_music_db, AudioServer.get_bus_volume_db(_music_idx), _base_db, restore_time)


func _set_music_db(v: float) -> void:
	AudioServer.set_bus_volume_db(_music_idx, v)
