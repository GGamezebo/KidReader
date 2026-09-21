class_name SaveManager
extends Node

const SAVE_PATH := "user://save/progress.json"
const SAVE_DEBOUNCE_SEC := 4.0

@export var pdata: PData
@export var root_events: RootEvents

var _dirty: bool = false
var _in_level: bool = false
var _shutting_down: bool = false
var _debounce_timer: Timer


func _ready() -> void:
	_debounce_timer = Timer.new()
	_debounce_timer.one_shot = true
	_debounce_timer.process_mode = Node.PROCESS_MODE_ALWAYS
	_debounce_timer.timeout.connect(_flush)
	add_child(_debounce_timer)
	_ensure_save_dir()
	load_pdata()
	if root_events:
		root_events.ev_save_progress.connect(save)
		root_events.ev_level_started.connect(_on_level_started)
		root_events.ev_level_finished.connect(_on_level_finished)


func _ensure_save_dir() -> void:
	var abs_dir := ProjectSettings.globalize_path("user://save")
	DirAccess.make_dir_recursive_absolute(abs_dir)


func load_pdata() -> void:
	if pdata == null:
		return
	var result := ResourceUtils.load_json(SAVE_PATH)
	var status: int = int(result["status"])
	if status == ResourceUtils.JsonLoadStatus.OK:
		pdata.apply_dict(result["data"])
	elif status == ResourceUtils.JsonLoadStatus.CORRUPT:
		var bak := ResourceUtils.load_json(ResourceUtils.bak_path(SAVE_PATH))
		if int(bak["status"]) == ResourceUtils.JsonLoadStatus.OK:
			pdata.apply_dict(bak["data"])
		else:
			pdata.reset_to_defaults()
	else:
		pdata.reset_to_defaults()


func save() -> void:
	_dirty = true
	if _shutting_down:
		_flush()
		return
	if _in_level:
		return
	_debounce_timer.start(SAVE_DEBOUNCE_SEC)


func _flush() -> void:
	if not _dirty or pdata == null:
		return
	_dirty = false
	if _debounce_timer:
		_debounce_timer.stop()
	ResourceUtils.save_json(SAVE_PATH, pdata.to_dict())


func _on_level_started() -> void:
	_in_level = true


func _on_level_finished() -> void:
	_in_level = false
	_flush.call_deferred()


func _notification(what: int) -> void:
	match what:
		NOTIFICATION_WM_CLOSE_REQUEST, NOTIFICATION_WM_GO_BACK_REQUEST:
			_shutting_down = true
			_flush()
		NOTIFICATION_APPLICATION_PAUSED, NOTIFICATION_APPLICATION_FOCUS_OUT:
			_flush()
