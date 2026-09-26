class_name SfxController
extends Node

@export var game_events: GameEvents
@export var audio_duck: AudioDuck
@export var voice_player: AudioStreamPlayer
@export var sfx_player: AudioStreamPlayer
## Recorded letter sounds + words; missing entries fall back to ToneSynth.
@export var voice_bank: VoiceBank

var _listener: EventListener = EventListener.new()
var _phoneme_cache: Dictionary = {}


func _ready() -> void:
	if voice_player:
		voice_player.bus = "Voice"
	if sfx_player:
		sfx_player.bus = "SFX"
	if game_events:
		_listener.add(game_events.ev_play_phoneme, _on_phoneme)
		_listener.add(game_events.ev_play_word, _on_word)
		_listener.add(game_events.ev_tile_wrong, _on_wrong)
		_listener.add(game_events.ev_tile_correct, _on_correct)
		_listener.add(game_events.ev_ice_cracked, _on_crack)
		_listener.add(game_events.ev_animal_freed, _on_free)


func _exit_tree() -> void:
	_listener.deinit()


func _on_phoneme(part: String) -> void:
	_play_phoneme(part, true)


func _on_word(word: String) -> void:
	var stream := voice_bank.get_word(word) if voice_bank else null
	if stream == null:
		stream = ToneSynth.make_word_fanfare(word)
	_play_stream(voice_player, stream, true)


## Seconds the voice clip for `part` lasts — lets callers pace letter-by-letter playback.
func get_phoneme_length(part: String) -> float:
	var stream := _phoneme_stream(part)
	return stream.get_length() if stream else 0.0


func _on_wrong(_part: String) -> void:
	_play_stream(sfx_player, ToneSynth.make_boing(), false)


func _on_correct(_part: String, _slot: int) -> void:
	_play_stream(sfx_player, ToneSynth.make_sparkle(), false)


func _on_crack(_progress: float) -> void:
	_play_stream(sfx_player, ToneSynth.make_crack(), false)


func _on_free() -> void:
	_play_stream(sfx_player, ToneSynth.make_tone(523.25, 0.35, 0.35), false)
	_play_stream(voice_player, ToneSynth.make_tone(659.25, 0.4, 0.3), true)


func _play_phoneme(part: String, duck: bool) -> void:
	_play_stream(voice_player, _phoneme_stream(part), duck)


func _phoneme_stream(part: String) -> AudioStream:
	if not _phoneme_cache.has(part):
		var stream := voice_bank.get_letter(part) if voice_bank else null
		if stream == null:
			stream = ToneSynth.make_tone(ToneSynth.phoneme_freq(part), 0.16, 0.38)
		_phoneme_cache[part] = stream
	return _phoneme_cache[part]


func _play_stream(player: AudioStreamPlayer, stream: AudioStream, duck: bool) -> void:
	if player == null or stream == null:
		return
	if duck and audio_duck:
		audio_duck.duck(maxf(0.28, stream.get_length()))
	player.stream = stream
	player.play()
