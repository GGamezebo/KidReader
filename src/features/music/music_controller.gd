class_name MusicController
extends Node

@export var music_player: AudioStreamPlayer
@export var background_volume_db: float = -10.0


func _ready() -> void:
	if music_player == null:
		return
	music_player.bus = "Music"
	if music_player.stream == null:
		music_player.stream = ToneSynth.make_music_loop()
	music_player.volume_db = background_volume_db
	if not music_player.playing:
		music_player.play()
