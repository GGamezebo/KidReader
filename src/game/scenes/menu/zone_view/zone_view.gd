class_name ZoneView
extends Control

## Zone screen: a horizontal row of enclosures (one per level) + festival tent at the end.
## Everything is driven by ZoneData/RegionData; enclosures are instances of `enclosure_scene`.

signal ev_level_selected(level_id: int)
signal ev_festival_selected(zone: ZoneData)

@export var catalog: LevelsCatalog
@export var pdata: PData
@export var voice_bank: VoiceBank
@export var enclosure_scene: PackedScene

@export_group("Nodes")
@export var title_label: Label
@export var paws_label: Label
@export var scroll: ScrollContainer
@export var row: HBoxContainer
@export var sky: ColorRect
@export var ground: ColorRect
@export var decor: Control
@export var festival_button: BaseButton
@export var festival_tent: Control
@export var festival_ribbon: Control
@export var festival_badge: Control
@export var festival_medal: Control
@export var voice_player: AudioStreamPlayer
@export var arrival: ArrivalOverlay

var zone: ZoneData
var _progress: ZooProgress
var _rng := RandomNumberGenerator.new()
var _pulse: Tween
## Zones whose «someone misses you» hint was already said this session.
var _hinted: Dictionary = {}


func _ready() -> void:
	festival_button.pressed.connect(_on_festival_pressed)
	decor.draw.connect(_draw_decor)
	_show_default.call_deferred()


## F6 / standalone: if nobody called show_zone() during the first frame, show the first zone.
func _show_default() -> void:
	if zone == null and catalog and not catalog.get_zones().is_empty():
		show_zone(catalog.get_zones()[0], ZooProgress.new(catalog, pdata))


func show_zone(p_zone: ZoneData, progress: ZooProgress) -> void:
	zone = p_zone
	_progress = progress
	var region := catalog.get_region_of_zone(zone.zone_id) if catalog else null
	var style := region.enclosure_style if region else "fence"
	title_label.text = "%s  %s" % [zone.icon, zone.display_name]
	paws_label.text = "🐾 %d/%d" % [progress.cleared_count(zone), zone.levels.size()]
	sky.color = region.sky_color if region else Color("CDEBF7")
	ground.color = zone.color.lerp(Color.WHITE, 0.35)
	decor.queue_redraw()

	for child in row.get_children():
		if child is Enclosure:
			row.remove_child(child)
			child.queue_free()
	var focus: Control = null
	var review := progress.review_in_zone(zone)
	for level in zone.levels:
		var enc := enclosure_scene.instantiate() as Enclosure
		row.add_child(enc)
		row.move_child(enc, festival_button.get_index())
		var state := Enclosure.State.LOCKED
		if progress.is_level_cleared(level.level_id):
			state = Enclosure.State.FILLED
		elif progress.is_level_unlocked(level.level_id):
			state = Enclosure.State.NEXT
			focus = enc
		enc.setup(level, state, style, level == review)
		if level == review and focus == null:
			focus = enc
		enc.ev_selected.connect(_on_enclosure_selected)
	_refresh_festival()
	_scroll_to.call_deferred(focus if focus else festival_button)
	if review and not _hinted.has(zone.zone_id):
		_hinted[zone.zone_id] = true
		_hint_review.call_deferred()


## Reward after a first win: the animal is delivered into its (already FILLED) enclosure.
func play_arrival(level_id: int) -> void:
	var enc: Enclosure = null
	for child in row.get_children():
		if child is Enclosure and (child as Enclosure).level.level_id == level_id:
			enc = child
	if enc == null:
		return
	await _scroll_to(enc)
	await get_tree().create_timer(0.4).timeout
	await arrival.play(enc.level, enc.sticker)
	enc.wiggle()


func _refresh_festival() -> void:
	var can_start := _progress.can_start_festival(zone)
	var passed := _progress.is_festival_passed(zone)
	festival_ribbon.visible = not can_start and not passed
	festival_badge.visible = can_start and not passed
	festival_medal.visible = passed
	festival_button.modulate.a = 1.0 if can_start or passed else 0.8
	if _pulse:
		_pulse.kill()
	if festival_badge.visible:
		festival_badge.pivot_offset = festival_badge.size * 0.5
		_pulse = create_tween().set_loops()
		_pulse.tween_property(festival_badge, "scale", Vector2(1.15, 1.15), 0.5).set_trans(Tween.TRANS_SINE)
		_pulse.tween_property(festival_badge, "scale", Vector2.ONE, 0.5).set_trans(Tween.TRANS_SINE)


func _scroll_to(target: Control) -> void:
	await get_tree().process_frame
	if target == null or not is_instance_valid(target):
		return
	var x := target.position.x + target.size.x * 0.5 - scroll.size.x * 0.5
	create_tween().tween_property(scroll, "scroll_horizontal", int(maxf(0.0, x)), 0.35)


func _on_enclosure_selected(enc: Enclosure) -> void:
	match enc.state:
		Enclosure.State.NEXT:
			ev_level_selected.emit(enc.level.level_id)
		Enclosure.State.FILLED:
			if enc.missing:
				ev_level_selected.emit(enc.level.level_id)
				return
			enc.wiggle()
			_say(enc.level.word)
		_:
			enc.wiggle()


func _on_festival_pressed() -> void:
	if _progress and _progress.can_start_festival(zone):
		ev_festival_selected.emit(zone)
		return
	var tw := create_tween()
	festival_tent.pivot_offset = festival_tent.size * 0.5
	for a in [6.0, -5.0, 3.0, 0.0]:
		tw.tween_property(festival_tent, "rotation_degrees", a, 0.07)


## Once per zone per session, unless an arrival is playing.
func _hint_review() -> void:
	await get_tree().create_timer(0.8).timeout
	if not is_visible_in_tree() or arrival.visible or voice_bank == null or voice_player == null:
		return
	var stream := voice_bank.get_phrase("review_hint")
	if stream:
		voice_player.stream = stream
		voice_player.play()


func _say(word: String) -> void:
	var stream := voice_bank.get_word(word) if voice_bank else null
	if stream and voice_player:
		voice_player.stream = stream
		voice_player.play()


## Soft procedural hills/bushes in darker shades of the zone color (same seed per zone → stable look).
func _draw_decor() -> void:
	if zone == null:
		return
	_rng.seed = hash(zone.zone_id)
	var w := decor.size.x
	var h := decor.size.y
	var dark := zone.color.darkened(0.25)
	for i in 9:
		var x := _rng.randf_range(0.0, w)
		var r := _rng.randf_range(40.0, 110.0)
		decor.draw_circle(Vector2(x, h * 0.42 + _rng.randf_range(-10, 30)), r, Color(dark, 0.35))
	for i in 7:
		var x := _rng.randf_range(0.0, w)
		decor.draw_circle(Vector2(x, h * 0.12 + _rng.randf_range(0, 50)), _rng.randf_range(16, 30), Color(1, 1, 1, 0.55))
