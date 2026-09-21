extends IScene

## Horizontal level map + settings behind parental gate.

@export var root_events: RootEvents
@export var catalog: LevelsCatalog
@export var pdata: PData
@export var user_settings: UserSettings
@export var level_card_scene: PackedScene
@export var levels_row: HBoxContainer
@export var levels_scroll: ScrollContainer
@export var settings_button: BaseButton
@export var music_button: BaseButton
@export var parental_gate: ParentalGate
@export var settings_panel: Control

var _listener: EventListener = EventListener.new()


func _ready() -> void:
	if level_card_scene == null:
		level_card_scene = load("res://src/game/scenes/menu/levels/level_card.tscn") as PackedScene
	if settings_button:
		settings_button.pressed.connect(_on_settings_pressed)
	if music_button:
		music_button.pressed.connect(_on_music_pressed)
	if parental_gate:
		parental_gate.ev_passed.connect(_open_settings)
	if settings_panel:
		settings_panel.visible = false
		var close_btn := settings_panel.get_node_or_null("Panel/VBox/CloseButton") as BaseButton
		if close_btn:
			close_btn.pressed.connect(func(): settings_panel.visible = false)
		var music_toggle := settings_panel.get_node_or_null("Panel/VBox/MusicToggle") as BaseButton
		var sfx_toggle := settings_panel.get_node_or_null("Panel/VBox/SfxToggle") as BaseButton
		if music_toggle:
			music_toggle.pressed.connect(_toggle_music)
		if sfx_toggle:
			sfx_toggle.pressed.connect(_toggle_sfx)


func initialize(_data: Dictionary = {}) -> void:
	_resolve_shared()
	_rebuild_levels()
	_refresh_audio_glyphs()
	if pdata:
		_listener.add(pdata.changed, _rebuild_levels)


func deinit() -> void:
	_listener.deinit()
	super.deinit()


func _resolve_shared() -> void:
	var n: Node = get_parent()
	while n:
		if root_events == null:
			var re: Variant = n.get("root_events")
			if re is RootEvents:
				root_events = re as RootEvents
		if pdata == null or catalog == null:
			var pc := n.get_node_or_null("Account/ProgressController") as ProgressController
			if pc == null:
				pc = n.get_node_or_null("ProgressController") as ProgressController
			if pc:
				if pdata == null and pc.pdata:
					pdata = pc.pdata
				if catalog == null and pc.catalog:
					catalog = pc.catalog
		if user_settings == null:
			var us: Variant = n.get("user_settings")
			if us is UserSettings:
				user_settings = us as UserSettings
		n = n.get_parent()


func _rebuild_levels(_a = null) -> void:
	if levels_row == null or catalog == null or level_card_scene == null:
		return
	for c in levels_row.get_children():
		c.queue_free()
	var focus_card: Control = null
	for level in catalog.levels:
		if level == null:
			continue
		var card := level_card_scene.instantiate() as LevelCard
		levels_row.add_child(card)
		var stars := 0
		var unlocked := level.level_id == 1
		if pdata:
			stars = pdata.get_stars(level.level_id)
			unlocked = pdata.is_unlocked(level.level_id)
		card.setup(level.level_id, level.animal_id, stars, not unlocked)
		card.ev_selected.connect(_on_level_selected)
		if unlocked and (stars <= 0 or focus_card == null):
			focus_card = card
	call_deferred("_scroll_to", focus_card)


func _scroll_to(card: Control) -> void:
	if levels_scroll == null or card == null:
		return
	await get_tree().process_frame
	var target := maxf(0.0, card.position.x - 40.0)
	levels_scroll.scroll_horizontal = int(target)


func _on_level_selected(level_id: int) -> void:
	if root_events:
		root_events.ev_start_level.emit({"level_id": level_id})


func _on_settings_pressed() -> void:
	if parental_gate:
		parental_gate.open()
	else:
		_open_settings()


func _open_settings() -> void:
	if settings_panel:
		settings_panel.visible = true
		_refresh_audio_glyphs()


func _on_music_pressed() -> void:
	_toggle_music()


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
	if music_button:
		music_button.text = "🔇" if user_settings.is_music_mute else "🎵"
	if settings_panel:
		var music_toggle := settings_panel.get_node_or_null("Panel/VBox/MusicToggle") as BaseButton
		var sfx_toggle := settings_panel.get_node_or_null("Panel/VBox/SfxToggle") as BaseButton
		if music_toggle:
			music_toggle.text = "🔇" if user_settings.is_music_mute else "🎵"
		if sfx_toggle:
			sfx_toggle.text = "🔕" if user_settings.is_sound_mute else "🔊"
