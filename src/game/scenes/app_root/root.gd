extends IScene

## App-root: shared progress/music + RootEvents → HFSM bridge.

@export var root_events: RootEvents
@export var progress_controller: ProgressController
@export var save_manager: SaveManager
@export var music_player: AudioStreamPlayer
@export var user_settings: UserSettings

var _listener: EventListener = EventListener.new()


func initialize(_data: Dictionary) -> void:
	_listener.add(root_events.ev_start_level, _on_ev_start_level)
	_listener.add(root_events.ev_return_to_menu, _on_ev_return_to_menu)
	_listener.add(root_events.ev_start_festival, _on_ev_start_festival)
	if user_settings:
		user_settings.load_from_disk()
		_apply_audio_buses()
		_listener.add(user_settings.ev_changed, _apply_audio_buses)
	if music_player and not music_player.playing:
		music_player.play()


func deinit() -> void:
	_listener.deinit()
	super.deinit()


func _on_ev_start_level(data: Dictionary) -> void:
	add_event("ev.start_level", data)


func _on_ev_return_to_menu(data: Dictionary = {}) -> void:
	add_event("ev.open_menu", data)


func _on_ev_start_festival(data: Dictionary) -> void:
	add_event("ev.start_festival", data)


func _apply_audio_buses(_a = null) -> void:
	if user_settings == null:
		return
	var music_idx := AudioServer.get_bus_index("Music")
	var sfx_idx := AudioServer.get_bus_index("SFX")
	var voice_idx := AudioServer.get_bus_index("Voice")
	if music_idx >= 0:
		AudioServer.set_bus_mute(music_idx, user_settings.is_music_mute)
	if sfx_idx >= 0:
		AudioServer.set_bus_mute(sfx_idx, user_settings.is_sound_mute)
	if voice_idx >= 0:
		AudioServer.set_bus_mute(voice_idx, user_settings.is_sound_mute)
