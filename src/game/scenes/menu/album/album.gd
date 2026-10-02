class_name AlbumView
extends Control

## Animal album (menu window): every zone as a section of stickers; collected animals open a big card
## that says the word, then reads the animal's fact. Uncollected slots wiggle and say «not here yet».

@export var catalog: LevelsCatalog
@export var pdata: PData
@export var voice_bank: VoiceBank
@export var zone_scene: PackedScene
## Pause between the word and the fact.
@export var fact_delay: float = 0.4

@export_group("Nodes")
@export var count_label: Label
@export var scroll: ScrollContainer
@export var sections: VBoxContainer
@export var card: Control
@export var card_panel: Control
@export var card_dim: BaseButton
@export var card_sticker: PhotoSticker
@export var card_sign: SignPlate
@export var card_fact: Label
@export var card_speak: BaseButton
@export var card_close: BaseButton
@export var voice_player: AudioStreamPlayer

var _level: LevelData
## Bumped on every new reading so an older word→fact sequence stops.
var _read_id: int = 0
var _built: bool = false


func _ready() -> void:
	card.visible = false
	card_dim.pressed.connect(_close_card)
	card_close.pressed.connect(_close_card)
	card_speak.pressed.connect(func(): _read(_level))
	_show_default.call_deferred()


## F6 / standalone: show the default profile if nobody called show_album() in the first frame.
func _show_default() -> void:
	if not _built and catalog:
		show_album(ZooProgress.new(catalog, pdata))


func show_album(progress: ZooProgress) -> void:
	_built = true
	_close_card()
	count_label.text = "🐾 %d / %d" % [progress.total_cleared(), catalog.count()]
	for child in sections.get_children():
		sections.remove_child(child)
		child.queue_free()
	for zone in catalog.get_zones():
		var section := zone_scene.instantiate() as AlbumZone
		sections.add_child(section)
		section.setup(zone, progress)
		section.ev_entry_chosen.connect(_on_entry_chosen)
	scroll.scroll_vertical = 0


func _on_entry_chosen(entry: AlbumEntry) -> void:
	if not entry.collected:
		entry.wiggle()
		_read_id += 1
		_say(voice_bank.get_phrase("album_empty") if voice_bank else null)
		return
	_open_card(entry.level)


func _open_card(level: LevelData) -> void:
	_level = level
	card.visible = true
	card_sticker.setup(level.animal_texture, PhotoSticker.State.FILLED, level.emoji)
	card_sign.setup(level.word)
	card_fact.text = level.fact
	card_panel.pivot_offset = card_panel.size * 0.5
	card_panel.scale = Vector2(0.7, 0.7)
	create_tween().tween_property(card_panel, "scale", Vector2.ONE, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_read(level)


func _close_card() -> void:
	_read_id += 1
	card.visible = false
	if voice_player:
		voice_player.stop()


## Word first (what the child just read), then the fact.
func _read(level: LevelData) -> void:
	if level == null or voice_bank == null:
		return
	_read_id += 1
	var my_id := _read_id
	var word_len := _say(voice_bank.get_word(level.word))
	await get_tree().create_timer(word_len + fact_delay).timeout
	if my_id == _read_id and card.visible:
		_say(voice_bank.get_fact(level.animal_id))


func _say(stream: AudioStream) -> float:
	if stream == null or voice_player == null:
		return 0.0
	voice_player.stream = stream
	voice_player.play()
	return stream.get_length()
