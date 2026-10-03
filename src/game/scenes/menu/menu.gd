extends IScene

## Zoo menu host: ZooMap ⇄ ZoneView (+ Album) via WindowStackManager; ParentCorner behind the parental gate.
## initialize({"zone_id": ..., "arrived_level_id": ...}) reopens that zone (returning from a level)
## and, after a first win, plays the animal's arrival there.
## initialize({"unlocked_zone_id": ...}) — after a first festival: the map glides to the new zone and unlocks it.

@export var root_events: RootEvents
@export var catalog: LevelsCatalog
@export var pdata: PData
@export var user_settings: UserSettings
@export var zoo_map: ZooMap
@export var zone_view: ZoneView
@export var album: AlbumView
@export var album_button: BaseButton
@export var window_stack: WindowStackManager
@export var settings_button: BaseButton
@export var music_button: BaseButton
@export var parental_gate: ParentalGate
@export var parent_corner: ParentCorner
## Editor-only cheats; frees itself in exported builds.
@export var dev_panel: DevPanel
@export var voice_bank: VoiceBank
@export var voice_player: AudioStreamPlayer

var _listener: EventListener = EventListener.new()
var _progress_controller: ProgressController
## F6 (no AppRoot): a detached controller so dev cheats still work on the scene's PData.
var _dev_controller: ProgressController


func _ready() -> void:
	settings_button.pressed.connect(_on_settings_pressed)
	music_button.pressed.connect(_toggle_music)
	parental_gate.ev_passed.connect(_open_parent_corner)
	parent_corner.ev_toggle_music.connect(_toggle_music)
	parent_corner.ev_toggle_sfx.connect(_toggle_sfx)
	parent_corner.ev_reset_confirmed.connect(_reset_progress)
	if is_instance_valid(dev_panel):
		dev_panel.ev_action.connect(_on_dev_action)
	zoo_map.ev_zone_selected.connect(_open_zone)
	zoo_map.ev_decor_placed.connect(_on_decor_placed)
	zoo_map.ev_decor_removed.connect(_on_decor_removed)
	zone_view.ev_level_selected.connect(_on_level_selected)
	zone_view.ev_festival_selected.connect(_on_festival_selected)
	album_button.pressed.connect(_open_album)
	super._ready()


func initialize(data: Dictionary = {}) -> void:
	_resolve_shared()
	zoo_map.catalog = catalog
	zoo_map.pdata = pdata
	zone_view.catalog = catalog
	zone_view.pdata = pdata
	album.catalog = catalog
	album.pdata = pdata
	_refresh()
	_refresh_audio_glyphs()
	_listener.add(pdata.changed, _refresh)
	var progress := _progress()
	var unlocked := catalog.get_zone(str(data.get("unlocked_zone_id", "")))
	if unlocked:
		_play_unlock(unlocked)
		return
	var zone := catalog.get_zone(str(data.get("zone_id", "")))
	if zone and progress.is_zone_unlocked(zone):
		zoo_map.scroll_to_zone(zone)
		_open_zone(zone)
		var arrived := int(data.get("arrived_level_id", -1))
		if arrived > 0:
			zone_view.play_arrival(arrived)
	else:
		zoo_map.scroll_to_zone(progress.current_zone())


func deinit() -> void:
	_listener.deinit()
	if _dev_controller:
		_dev_controller.free()
		_dev_controller = null
	super.deinit()


func _progress() -> ZooProgress:
	return ZooProgress.new(catalog, pdata)


func _refresh(_a = null) -> void:
	var progress := _progress()
	zoo_map.build(progress)
	if zone_view.zone:
		zone_view.show_zone(zone_view.zone, progress)


func _open_zone(zone: ZoneData) -> void:
	zone_view.show_zone(zone, _progress())
	window_stack.open_stacked_window(zone_view)


func _on_decor_placed(decor_id: String, pos: Vector2) -> void:
	if _progress_controller:
		_progress_controller.place_decor(decor_id, pos)


func _on_decor_removed(decor_id: String) -> void:
	if _progress_controller:
		_progress_controller.remove_decor(decor_id)


func _open_album() -> void:
	album.show_album(_progress())
	window_stack.open_stacked_window(album)


func _play_unlock(zone: ZoneData) -> void:
	await zoo_map.play_unlock(zone)
	var phrase := voice_bank.get_phrase("zone_unlocked") if voice_bank else null
	if phrase and voice_player:
		voice_player.stream = phrase
		voice_player.play()
		await get_tree().create_timer(phrase.get_length() + 0.3).timeout
	await zoo_map.play_egg_moment(zone)


func _on_festival_selected(zone: ZoneData) -> void:
	if root_events:
		root_events.ev_start_festival.emit({"zone_id": zone.zone_id})


func _on_level_selected(level_id: int) -> void:
	if root_events:
		root_events.ev_start_level.emit({"level_id": level_id})


func _resolve_shared() -> void:
	var n: Node = get_parent()
	while n:
		if root_events == null:
			var re: Variant = n.get("root_events")
			if re is RootEvents:
				root_events = re as RootEvents
		var pc := n.get_node_or_null("Account/ProgressController") as ProgressController
		if pc:
			_progress_controller = pc
			if pc.pdata:
				pdata = pc.pdata
			if pc.catalog:
				catalog = pc.catalog
		var us: Variant = n.get("user_settings")
		if us is UserSettings:
			user_settings = us as UserSettings
		n = n.get_parent()


func _on_settings_pressed() -> void:
	parental_gate.open()


func _open_parent_corner() -> void:
	_refresh_audio_glyphs()
	parent_corner.open(_parent_stats())


## Full stats from ProgressController; standalone (F6) falls back to what ZooProgress knows.
func _parent_stats() -> Dictionary:
	if _progress_controller:
		return _progress_controller.get_parent_stats()
	var progress := _progress()
	return {"animals": progress.total_cleared(), "animals_total": catalog.count(),
		"zones_total": catalog.get_zones().size()}


func _reset_progress() -> void:
	if _progress_controller:
		_progress_controller.reset_progress()
	elif pdata:
		pdata.reset_to_defaults()
	_close_windows()
	zoo_map.scroll_to_zone(_progress().current_zone())


func _close_windows() -> void:
	while window_stack.window_stack.size() > 1:
		window_stack.close_stacked_window()


func _on_dev_action(action: String) -> void:
	var pc := _progress_controller
	if pc == null:
		if _dev_controller == null:
			_dev_controller = ProgressController.new()
			_dev_controller.pdata = pdata
			_dev_controller.catalog = catalog
		pc = _dev_controller
	var zone := _progress().current_zone()
	match action:
		"unlock_all":
			pc.dev_unlock_all()
		"next_animal":
			var level_id := _progress().next_level_in_zone(zone)
			if level_id > 0:
				pc.record_win(level_id, 3)
				_close_windows()
				_open_zone(zone)
				zone_view.play_arrival(level_id)
		"fill_zone":
			pc.dev_fill_zone(zone)
		"pass_festival":
			pc.dev_fill_zone(zone)
			var result := pc.record_festival(zone.zone_id, 3)
			_close_windows()
			var next := catalog.get_zone(str(result.get("next_zone_id", "")))
			if bool(result.get("first_pass", false)) and next:
				_play_unlock(next)
		"all_miss":
			pc.dev_make_all_miss()
		"reset":
			_reset_progress()


func _toggle_music() -> void:
	if user_settings == null:
		return
	user_settings.set_music_mute(not user_settings.is_music_mute)
	_refresh_audio_glyphs()


func _toggle_sfx() -> void:
	if user_settings == null:
		return
	user_settings.set_sound_mute(not user_settings.is_sound_mute)
	_refresh_audio_glyphs()


func _refresh_audio_glyphs() -> void:
	if user_settings == null:
		return
	var music := "🔇" if user_settings.is_music_mute else "🎵"
	music_button.text = music
	parent_corner.set_audio(user_settings.is_music_mute, user_settings.is_sound_mute)
