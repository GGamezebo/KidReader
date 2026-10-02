extends IScene

## Zone festival («Прочитай и найди»): the word is written on the sign (NOT spoken), the child taps the matching
## animal among 3–6 cards. One round per animal of the zone; no timer, no failing. Then joy → next zone unlocks.
## initialize({"zone_id": String}).

@export var root_events: RootEvents
@export var catalog: LevelsCatalog
@export var voice_bank: VoiceBank
@export var card_scene: PackedScene
@export var dot_scene: PackedScene
## Card side by card count (3 / 4 / 6 cards).
@export var card_sizes: Dictionary = {3: 240, 4: 220, 6: 180}

@export_group("Nodes")
@export var home_button: BaseButton
@export var bunting: Control
@export var dots_row: HBoxContainer
@export var sign_plate: SignPlate
@export var cards_row: HBoxContainer
@export var joy: JoyOverlay
@export var voice_player: AudioStreamPlayer

var zone: ZoneData
var _rounds: Array[Dictionary] = []
var _round: int = 0
var _round_mistakes: int = 0
var _mistakes: int = 0
var _busy: bool = false
var _next_zone: ZoneData
var _first_pass: bool = false
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	_rng.randomize()
	home_button.pressed.connect(_back_to_zone)
	bunting.draw.connect(_draw_bunting)
	joy.ev_continue.connect(_on_continue)
	super._ready()


func initialize(data: Dictionary = {}) -> void:
	_resolve_shared()
	zone = catalog.get_zone(str(data.get("zone_id", "")))
	if zone == null:
		zone = catalog.get_zones()[0]
	_rounds = FestivalRounds.build(zone, catalog, _rng)
	for child in dots_row.get_children():
		child.queue_free()
	for i in _rounds.size():
		var dot := dot_scene.instantiate() as RoundDot
		dots_row.add_child(dot)
	_round = 0
	_mistakes = 0
	_show_round()
	_say(voice_bank.get_phrase("festival_intro") if voice_bank else null)


func _resolve_shared() -> void:
	var n: Node = get_parent()
	while n:
		if root_events == null:
			var re: Variant = n.get("root_events")
			if re is RootEvents:
				root_events = re as RootEvents
		var pc := n.get_node_or_null("Account/ProgressController") as ProgressController
		if pc and pc.catalog:
			catalog = pc.catalog
		n = n.get_parent()


func _find_progress() -> ProgressController:
	var n: Node = get_parent()
	while n:
		var pc := n.get_node_or_null("Account/ProgressController") as ProgressController
		if pc:
			return pc
		n = n.get_parent()
	return null


func _show_round() -> void:
	_round_mistakes = 0
	_busy = false
	var r: Dictionary = _rounds[_round]
	var target: LevelData = r["target"]
	sign_plate.setup(target.word)
	sign_plate.pivot_offset = sign_plate.size * 0.5
	sign_plate.scale = Vector2(0.6, 0.6)
	create_tween().tween_property(sign_plate, "scale", Vector2.ONE, 0.3).set_trans(Tween.TRANS_BACK)
	for i in dots_row.get_child_count():
		var state := RoundDot.State.TODO
		if i < _round:
			state = RoundDot.State.DONE
		elif i == _round:
			state = RoundDot.State.NOW
		(dots_row.get_child(i) as RoundDot).setup(i + 1, state)
	for child in cards_row.get_children():
		cards_row.remove_child(child)
		child.queue_free()
	var cards: Array = r["cards"]
	var side: float = card_sizes.get(cards.size(), 180)
	for level in cards:
		var card := card_scene.instantiate() as FestivalCard
		cards_row.add_child(card)
		card.setup(level, side)
		card.ev_chosen.connect(_on_card_chosen)


func _on_card_chosen(card: FestivalCard) -> void:
	if _busy:
		return
	var target: LevelData = _rounds[_round]["target"]
	if card.level == target:
		_busy = true
		card.celebrate()
		await get_tree().create_timer(maxf(1.0, _say(voice_bank.get_word(target.word) if voice_bank else null) + 0.2)).timeout
		_round += 1
		if _round >= _rounds.size():
			_finish()
		else:
			_show_round()
		return
	card.reject()
	_mistakes += 1
	_round_mistakes += 1
	if _round_mistakes == 2:
		_help_read(target)


## After two misses: the word is sounded out letter by letter (help, not a penalty).
func _help_read(target: LevelData) -> void:
	_busy = true
	await get_tree().create_timer(maxf(0.3, _say(voice_bank.get_phrase("festival_try_again") if voice_bank else null))).timeout
	for part in target.parts:
		await get_tree().create_timer(maxf(0.35, _say(voice_bank.get_letter(part) if voice_bank else null))).timeout
	_busy = false


func _finish() -> void:
	for i in dots_row.get_child_count():
		(dots_row.get_child(i) as RoundDot).setup(i + 1, RoundDot.State.DONE)
	var stars := FestivalRounds.stars_for(_mistakes)
	var result := {}
	var progress := _find_progress()
	if progress:
		result = progress.record_festival(zone.zone_id, stars)
	_first_pass = bool(result.get("first_pass", false))
	_next_zone = catalog.next_zone(zone.zone_id)
	_say(voice_bank.get_phrase("festival_win") if voice_bank else null)
	joy.play(zone, stars, _next_zone if _first_pass else null)


func _on_continue() -> void:
	if root_events == null:
		return
	if _first_pass and _next_zone:
		root_events.ev_return_to_menu.emit({"unlocked_zone_id": _next_zone.zone_id})
	else:
		_back_to_zone()


func _back_to_zone() -> void:
	if root_events:
		root_events.ev_return_to_menu.emit({"zone_id": zone.zone_id})


func _say(stream: AudioStream) -> float:
	if stream == null or voice_player == null:
		return 0.0
	voice_player.stream = stream
	voice_player.play()
	return stream.get_length()


## Garland of little flags across the top (procedural).
func _draw_bunting() -> void:
	var w := bunting.size.x
	var colors := [Color("E53935"), Color("FFC94A"), Color("73C76B"), Color("8CC7F2")]
	var sag := 26.0
	var points := PackedVector2Array()
	for i in 33:
		var x := w * i / 32.0
		points.append(Vector2(x, 8.0 + sag * sin(PI * i / 32.0)))
	bunting.draw_polyline(points, Color("8F5E33"), 3.0, true)
	var n := int(w / 64.0)
	for i in n:
		var x := (i + 0.5) * w / n
		var y := 8.0 + sag * sin(PI * x / w)
		bunting.draw_colored_polygon(PackedVector2Array([Vector2(x - 18, y), Vector2(x + 18, y), Vector2(x, y + 40)]), colors[i % colors.size()])
