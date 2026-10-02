class_name ArrivalOverlay
extends Control

## «Animal arrives» reward (3–5 s, tap to hurry): a balloon lowers the frosted card, the word's letters pop in
## one by one with their sounds, the word is spoken while the photo clears, then the card flies into its enclosure.

signal ev_finished

@export var letter_scene: PackedScene
@export var voice_bank: VoiceBank
@export var voice_player: AudioStreamPlayer
@export var dim: Control
@export var carrier: Control
@export var sticker: PhotoSticker
@export var letters_row: HBoxContainer
@export var fx_host: Control
@export var confetti_colors: Array[Color] = [Color("E53935"), Color("FFC94A"), Color("73C76B"), Color("8CC7F2")]

var _hurry: bool = false


func _ready() -> void:
	visible = false
	gui_input.connect(_on_gui_input)


## Plays the whole sequence and lands the card on `target` (the enclosure's own sticker).
func play(level: LevelData, target: PhotoSticker) -> void:
	_hurry = false
	visible = true
	modulate.a = 1.0
	for child in letters_row.get_children():
		child.queue_free()
	for child in fx_host.get_children():
		child.queue_free()
	target.modulate.a = 0.0
	sticker.setup(level.animal_texture, PhotoSticker.State.FROST)
	sticker.scale = Vector2.ONE
	var land := Vector2((size.x - carrier.size.x) * 0.5, size.y * 0.06)
	carrier.position = Vector2(land.x, -carrier.size.y)
	dim.modulate.a = 0.0

	var tw := create_tween().set_parallel()
	tw.tween_property(dim, "modulate:a", 1.0, 0.3)
	tw.tween_property(carrier, "position", land, 0.9).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	await _wait(0.95)

	for part in level.parts:
		var letter := letter_scene.instantiate() as Control
		letters_row.add_child(letter)
		(letter.get_node("Label") as Label).text = part
		letter.scale = Vector2.ZERO
		create_tween().tween_property(letter, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		await _wait(maxf(0.35, _say(voice_bank.get_letter(part) if voice_bank else null)))

	var word_len := _say(voice_bank.get_word(level.word) if voice_bank else null)
	create_tween().tween_method(sticker.set_frost, 1.0, 0.0, 0.7)
	for letter in letters_row.get_children():
		var hop := create_tween()
		hop.tween_property(letter, "position:y", -18.0, 0.15).set_trans(Tween.TRANS_SINE)
		hop.tween_property(letter, "position:y", 0.0, 0.2).set_trans(Tween.TRANS_BOUNCE)
	_burst_confetti()
	await _wait(maxf(1.0, word_len + 0.3))

	# Card flies into the enclosure, balloon floats away.
	var home := sticker.position
	var from := sticker.global_position
	var target_scale := target.size.x / sticker.size.x
	var balloon := carrier.get_node("Balloon") as Control
	sticker.top_level = true
	sticker.global_position = from
	var fly := create_tween().set_parallel()
	fly.tween_property(sticker, "global_position", target.global_position, 0.6).set_trans(Tween.TRANS_SINE)
	fly.tween_property(sticker, "scale", Vector2.ONE * target_scale, 0.6).set_trans(Tween.TRANS_SINE)
	fly.tween_property(balloon, "position:y", balloon.position.y - size.y, 0.9).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	fly.tween_property(dim, "modulate:a", 0.0, 0.5)
	fly.tween_property(letters_row, "modulate:a", 0.0, 0.4)
	await fly.finished
	target.modulate.a = 1.0
	sticker.top_level = false
	sticker.position = home
	balloon.position.y += size.y
	letters_row.modulate.a = 1.0
	visible = false
	ev_finished.emit()


## Plays a clip, returns its length (0 when missing).
func _say(stream: AudioStream) -> float:
	if stream == null or voice_player == null:
		return 0.0
	voice_player.stream = stream
	voice_player.play()
	return stream.get_length()


func _wait(sec: float) -> void:
	var left := sec
	while left > 0.0 and not _hurry:
		await get_tree().process_frame
		left -= get_process_delta_time()


func _burst_confetti() -> void:
	var center := carrier.position + carrier.size * Vector2(0.5, 0.6)
	for i in 24:
		# Throw-away FX pieces (allowed by ui-scenes rule).
		var bit := ColorRect.new()
		bit.color = confetti_colors[i % confetti_colors.size()]
		bit.size = Vector2(12, 20)
		bit.pivot_offset = bit.size * 0.5
		bit.mouse_filter = Control.MOUSE_FILTER_IGNORE
		bit.position = center
		fx_host.add_child(bit)
		var dir := Vector2.from_angle(randf_range(-PI * 0.95, -PI * 0.05)) * randf_range(220.0, 420.0)
		var tw := create_tween().set_parallel()
		tw.tween_property(bit, "position", center + dir + Vector2(0, 260), 1.3).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tw.tween_property(bit, "rotation", randf_range(-6.0, 6.0), 1.3)
		tw.tween_property(bit, "modulate:a", 0.0, 1.3).set_delay(0.5)


func _on_gui_input(event: InputEvent) -> void:
	var tap := (event is InputEventMouseButton and (event as InputEventMouseButton).pressed) \
		or (event is InputEventScreenTouch and (event as InputEventScreenTouch).pressed)
	if tap:
		_hurry = true
		accept_event()
