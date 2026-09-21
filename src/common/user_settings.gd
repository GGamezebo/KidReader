class_name UserSettings
extends Resource

## JSON settings under user://settings.json

const SAVE_PATH := "user://settings.json"
const VERSION := 1

@export var version: int = VERSION
@export var is_music_mute: bool = false
@export var is_sound_mute: bool = false

@warning_ignore("unused_signal") signal ev_changed


func to_dict() -> Dictionary:
	return {
		"version": version,
		"is_music_mute": is_music_mute,
		"is_sound_mute": is_sound_mute,
	}


func apply_dict(data: Dictionary) -> void:
	version = int(data.get("version", VERSION))
	is_music_mute = bool(data.get("is_music_mute", false))
	is_sound_mute = bool(data.get("is_sound_mute", false))
	emit_changed()
	ev_changed.emit()


func load_from_disk() -> void:
	var result := ResourceUtils.load_json(SAVE_PATH)
	if int(result["status"]) == ResourceUtils.JsonLoadStatus.OK:
		apply_dict(result["data"])
	else:
		save_to_disk()


func save_to_disk() -> void:
	ResourceUtils.save_json(SAVE_PATH, to_dict())
	ev_changed.emit()


func set_music_mute(value: bool) -> void:
	is_music_mute = value
	save_to_disk()


func set_sound_mute(value: bool) -> void:
	is_sound_mute = value
	save_to_disk()
