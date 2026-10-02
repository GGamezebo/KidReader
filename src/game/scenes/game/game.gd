extends IScene

## Letter-scatter level: realistic animal behind blur, magnet slots, fly-up reject.

@export var root_events: RootEvents
@export var game_events: GameEvents
@export var level_data: LevelData
@export var catalog: LevelsCatalog
@export var letter_tile_scene: PackedScene
@export var word_slot_scene: PackedScene
@export var animal_view: AnimalView
@export var celebration: CelebrationOverlay
@export var slots_row: HBoxContainer
@export var scatter_host: Control
@export var home_button: BaseButton
@export var next_button: BaseButton
@export var fx_host: Control
@export var sfx_controller: SfxController
@export var inactivity_sec: float = 6.0
@export var magnet_radius: float = 40.0
@export var low_reject_ratio: float = 0.62
## Letter cell side (slots + tiles). Shrinks for long words (up to 12 letters) so one row fits.
@export var max_cell_size: float = 100.0
@export var min_cell_size: float = 64.0

var _manager: GameManager
var _slots: Array[WordSlot] = []
var _tiles: Array[LetterTile] = []
var _filled_count: int = 0
var _idle_timer: float = 0.0
var _hinting: bool = false
var _active: bool = false
## Set on a first win: the zone screen plays the arrival of this animal.
var _arrived_level_id: int = -1
var _rng := RandomNumberGenerator.new()
var _cell_size: float = 100.0


func _ready() -> void:
	_rng.randomize()
	if home_button:
		home_button.pressed.connect(_on_home)
	if next_button:
		next_button.visible = false
		next_button.pressed.connect(_on_next)
	if celebration:
		celebration.ev_next_pressed.connect(_on_next)
		celebration.ev_home_pressed.connect(_on_home)
	if letter_tile_scene == null:
		letter_tile_scene = load("res://src/features/letter_tile/letter_tile.tscn") as PackedScene
	if word_slot_scene == null:
		word_slot_scene = load("res://src/features/word_slot/word_slot.tscn") as PackedScene


func _default_data() -> Dictionary:
	return {"level_data": level_data}


func initialize(data: Dictionary = {}) -> void:
	_resolve_shared()
	var incoming: LevelData = data.get("level_data") as LevelData
	if incoming == null and data.has("level_id") and catalog:
		incoming = catalog.get_by_id(int(data["level_id"]))
	if incoming:
		level_data = incoming.duplicate(true) as LevelData
	if level_data == null:
		push_error("GameScene: missing LevelData")
		return

	_manager = GameManager.new()
	add_child(_manager)
	_manager.setup(self)
	_build_level()
	if root_events:
		root_events.ev_level_started.emit()


func _resolve_shared() -> void:
	var n: Node = get_parent()
	while n:
		if root_events == null:
			var re = n.get("root_events")
			if re is RootEvents:
				root_events = re
		if catalog == null:
			var pc := n.get_node_or_null("Account/ProgressController") as ProgressController
			if pc and pc.catalog:
				catalog = pc.catalog
		n = n.get_parent()


func deinit() -> void:
	_active = false
	if _manager:
		_manager.deinit()
		_manager.queue_free()
		_manager = null
	if root_events:
		root_events.ev_level_finished.emit()
	super.deinit()


func _process(delta: float) -> void:
	if not _active:
		return
	_idle_timer += delta
	if not _hinting and _idle_timer >= inactivity_sec:
		_show_hint()


func on_fsm_playing() -> void:
	_active = true
	_idle_timer = 0.0
	_set_tiles_interactive(true)


func play_completion_sequence() -> void:
	_active = false
	_clear_hint()
	_set_tiles_interactive(false)
	for slot in _slots:
		if slot.filled:
			slot.flash()
			if game_events:
				game_events.ev_play_phoneme.emit(slot.expected)
			var clip_sec := sfx_controller.get_phoneme_length(slot.expected) if sfx_controller else 0.0
			await get_tree().create_timer(maxf(0.32, clip_sec + 0.08)).timeout
	if game_events:
		game_events.ev_play_word.emit(level_data.word)
	await get_tree().create_timer(0.4).timeout
	if animal_view:
		animal_view.reveal()
	if game_events:
		game_events.ev_animal_freed.emit()
	await get_tree().create_timer(0.45).timeout


func on_fsm_victory(stars: int) -> void:
	if game_events:
		game_events.ev_victory.emit(stars)
	var result := {}
	var progress := _find_progress()
	if progress:
		result = progress.record_win(level_data.level_id, stars)
	if bool(result.get("first_clear", false)):
		_arrived_level_id = level_data.level_id
	if next_button:
		next_button.visible = true
		_pulse_next()
	if celebration:
		# Light overlay optional — primary CTA is side next button like reference.
		celebration.visible = false


func _build_level() -> void:
	_clear_children(slots_row)
	_clear_children(scatter_host)
	_slots.clear()
	_tiles.clear()
	_filled_count = 0
	if next_button:
		next_button.visible = false
	if celebration:
		celebration.visible = false

	if animal_view:
		animal_view.setup(level_data.animal_id, level_data.animal_display_name, level_data.animal_texture, level_data.emoji)

	_cell_size = _fit_cell_size(level_data.parts.size())
	var revealed := {}
	for idx in level_data.revealed_indices:
		revealed[int(idx)] = true

	for i in level_data.parts.size():
		var part := str(level_data.parts[i])
		var slot := word_slot_scene.instantiate() as WordSlot
		slots_row.add_child(slot)
		slot.set_cell_size(_cell_size)
		var prefilled := revealed.has(i)
		slot.setup(i, part, level_data.show_ghost_hints, prefilled)
		slot.ev_tapped.connect(_on_slot_tapped)
		_slots.append(slot)
		if prefilled:
			_filled_count += 1

	var letters: Array[String] = []
	for i in level_data.parts.size():
		if not revealed.has(i):
			letters.append(str(level_data.parts[i]))
	letters.shuffle()

	call_deferred("_scatter_letters", letters)
	_update_blur()



func _fit_cell_size(count: int) -> float:
	if count <= 0:
		return max_cell_size
	var width := get_viewport().get_visible_rect().size.x
	var bar := slots_row.get_parent() as Control if slots_row else null
	if bar:
		width -= bar.get_theme_constant("margin_left") + bar.get_theme_constant("margin_right")
	var gap := slots_row.get_theme_constant("separation") if slots_row else 16
	var fit := (width - gap * (count - 1)) / float(count)
	return clampf(floorf(fit), min_cell_size, max_cell_size)

func _scatter_letters(letters: Array[String]) -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	if scatter_host == null:
		return
	var area := scatter_host.size
	if area.x < 10.0:
		area = get_viewport().get_visible_rect().size
	var used: Array[Rect2] = []
	for part in letters:
		var tile := letter_tile_scene.instantiate() as LetterTile
		scatter_host.add_child(tile)
		tile.set_cell_size(_cell_size)
		tile.setup(part)
		tile.ev_picked.connect(_on_tile_picked)
		tile.ev_drag_moved.connect(_on_tile_moved)
		tile.ev_dropped.connect(_on_tile_dropped)
		var pos := _find_scatter_pos(area, used)
		tile.position = pos
		used.append(Rect2(pos, tile.size))
		tile.scatter_pose(_rng.randf_range(-32.0, 32.0))
		_tiles.append(tile)
		# Animated toss-in
		tile.modulate.a = 0.0
		tile.scale = Vector2(0.4, 0.4)
		var tw := create_tween()
		tw.set_parallel(true)
		tw.tween_property(tile, "modulate:a", 1.0, 0.25)
		tw.tween_property(tile, "scale", Vector2.ONE, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _find_scatter_pos(area: Vector2, used: Array[Rect2]) -> Vector2:
	for _try in 40:
		var p := Vector2(
			_rng.randf_range(24.0, maxf(40.0, area.x - _cell_size - 20.0)),
			_rng.randf_range(area.y * 0.08, area.y * 0.55)
		)
		var r := Rect2(p, Vector2(_cell_size, _cell_size))
		var ok := true
		for u in used:
			if u.grow(18).intersects(r):
				ok = false
				break
		if ok:
			return p
	return Vector2(_rng.randf_range(40, area.x * 0.7), _rng.randf_range(40, area.y * 0.4))


func _on_tile_picked(tile: LetterTile) -> void:
	if not _active or tile.locked:
		return
	_bump_idle()
	if game_events:
		game_events.ev_tile_picked.emit(tile.part)
		game_events.ev_play_phoneme.emit(tile.part)


func _on_tile_moved(tile: LetterTile, global_pos: Vector2) -> void:
	for slot in _slots:
		if slot.filled:
			continue
		var center := slot.global_position + slot.size * 0.5
		var near := center.distance_to(global_pos) < magnet_radius
		slot.highlight(near and slot.accepts(tile.part))


func _on_tile_dropped(tile: LetterTile, global_pos: Vector2) -> void:
	if tile.locked:
		return
	if not _active:
		_repel_tile(tile)
		return
	_bump_idle()
	for slot in _slots:
		slot.highlight(false)

	var best: WordSlot = null
	var best_dist := 99999.0
	for slot in _slots:
		if not slot.accepts(tile.part):
			continue
		var center := slot.global_position + slot.size * 0.5
		var dist := center.distance_to(global_pos)
		if dist < magnet_radius and dist < best_dist:
			best = slot
			best_dist = dist

	if best:
		best.place_tile(tile)
		_filled_count += 1
		_update_blur()
		_spawn_sparks(best.global_position + best.size * 0.5)
		if game_events:
			game_events.ev_tile_correct.emit(tile.part, best.slot_index)
			game_events.ev_play_phoneme.emit(tile.part)
		if _filled_count >= level_data.parts.size():
			if game_events:
				game_events.ev_word_complete.emit(level_data.word)
			_manager.notify_word_complete()
	else:
		if _manager:
			_manager.wrong_drops += 1
		if game_events:
			game_events.ev_tile_wrong.emit(tile.part)
		_repel_tile(tile)


func _repel_tile(tile: LetterTile) -> void:
	var vp := get_viewport().get_visible_rect().size
	var low_line := vp.y * low_reject_ratio
	# Always fling up when miss; stronger if released low (near slots).
	if tile.global_position.y > low_line * 0.75:
		tile.fly_up_repel(vp)
	else:
		tile.fly_up_repel(vp)


func _on_slot_tapped(slot: WordSlot) -> void:
	if slot == null or not slot.filled:
		return
	if game_events:
		game_events.ev_play_phoneme.emit(slot.expected)


func _update_blur() -> void:
	if animal_view and level_data:
		animal_view.set_progress(float(_filled_count) / float(maxi(level_data.parts.size(), 1)))


func _show_hint() -> void:
	_hinting = true
	var needed := ""
	for slot in _slots:
		if not slot.filled:
			needed = slot.expected
			slot.highlight(true)
			break
	if needed.is_empty():
		return
	for tile in _tiles:
		if is_instance_valid(tile) and not tile.locked and tile.part == needed:
			tile.play_hint()
			if game_events:
				game_events.ev_hint_needed.emit()
			break


func _clear_hint() -> void:
	_hinting = false
	for slot in _slots:
		if not slot.filled:
			slot.highlight(false)
	for tile in _tiles:
		if is_instance_valid(tile):
			tile.stop_hint()


func _bump_idle() -> void:
	_idle_timer = 0.0
	if _hinting:
		_clear_hint()


func _pulse_next() -> void:
	if next_button == null:
		return
	next_button.pivot_offset = next_button.size * 0.5
	var pulse := create_tween().set_loops()
	pulse.tween_property(next_button, "scale", Vector2(1.1, 1.1), 0.45)
	pulse.tween_property(next_button, "scale", Vector2.ONE, 0.45)


func _on_home() -> void:
	if root_events:
		root_events.ev_return_to_menu.emit(_menu_payload())


## After a win the level always returns to its zone: the animal arrives there and the next enclosure pulses.
func _on_next() -> void:
	if root_events:
		root_events.ev_return_to_menu.emit(_menu_payload())


## Back to the zone this level belongs to (menu reopens it; plays the arrival after a first win).
func _menu_payload() -> Dictionary:
	var payload := {}
	var zone: ZoneData = catalog.get_zone_of_level(level_data.level_id) if catalog and level_data else null
	if zone:
		payload["zone_id"] = zone.zone_id
	if _arrived_level_id > 0:
		payload["arrived_level_id"] = _arrived_level_id
	return payload


func _find_progress() -> ProgressController:
	var n: Node = get_parent()
	while n:
		var nested := n.get_node_or_null("Account/ProgressController") as ProgressController
		if nested:
			return nested
		var direct := n.get_node_or_null("ProgressController") as ProgressController
		if direct:
			return direct
		n = n.get_parent()
	return get_tree().root.find_child("ProgressController", true, false) as ProgressController


func _spawn_sparks(at_global: Vector2) -> void:
	var host := fx_host if fx_host else scatter_host
	if host == null:
		return
	var colors := [Color("FFC94A"), Color("FFFFFF"), Color("7EC8E8"), Color("6BCB77")]
	for i in 10:
		var bit := ColorRect.new()
		bit.color = colors[i % colors.size()]
		bit.size = Vector2(8, 8)
		bit.mouse_filter = Control.MOUSE_FILTER_IGNORE
		host.add_child(bit)
		bit.global_position = at_global
		var dir := Vector2.from_angle(TAU * float(i) / 10.0) * randf_range(36.0, 90.0)
		var tw := create_tween()
		tw.set_parallel(true)
		tw.tween_property(bit, "global_position", at_global + dir, 0.35)
		tw.tween_property(bit, "modulate:a", 0.0, 0.35)
		tw.chain().tween_callback(bit.queue_free)


func _set_tiles_interactive(enabled: bool) -> void:
	for tile in _tiles:
		if not is_instance_valid(tile) or tile.locked:
			continue
		tile.mouse_filter = Control.MOUSE_FILTER_STOP if enabled else Control.MOUSE_FILTER_IGNORE
		if not enabled:
			tile.stop_hint()
			tile.stop_float()
			tile.is_dragging = false


func _clear_children(host: Node) -> void:
	if host == null:
		return
	for c in host.get_children():
		c.queue_free()
