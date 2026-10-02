class_name Enclosure
extends Button

## One animal's enclosure on the zone screen: photo sticker + procedural fence + word sign.
## FILLED = animal lives here (tap → hears its name), NEXT = frosted photo + pulsing ▶ (tap → level),
## LOCKED = empty frame (tap → wiggle). A FILLED animal may «miss» the child: bobbing 💭❗ (tap → replay its level).

signal ev_selected(enclosure: Enclosure)

enum State { FILLED, NEXT, LOCKED }

@export var sticker: PhotoSticker
@export var fence: EnclosureFence
@export var sign_plate: SignPlate
@export var play_badge: Control
@export var miss_bubble: Control

var level: LevelData
var state: State = State.LOCKED
var missing: bool = false
var _pulse: Tween
var _bob: Tween


func _ready() -> void:
	focus_mode = Control.FOCUS_NONE
	pressed.connect(func(): ev_selected.emit(self))


func setup(p_level: LevelData, p_state: State, enclosure_style: String, p_missing: bool = false) -> void:
	level = p_level
	state = p_state
	missing = p_missing and state == State.FILLED
	var sticker_state := PhotoSticker.State.FILLED
	if state == State.NEXT:
		sticker_state = PhotoSticker.State.FROST
	elif state == State.LOCKED:
		sticker_state = PhotoSticker.State.EMPTY
	sticker.setup(level.animal_texture if state != State.LOCKED else null, sticker_state, level.emoji)
	sticker.rotation_degrees = [-3.0, 2.0, -2.0, 3.0][absi(level.level_id) % 4]
	fence.style = enclosure_style
	sign_plate.setup(level.word, state != State.FILLED)
	play_badge.visible = state == State.NEXT
	modulate.a = 0.85 if state == State.LOCKED else 1.0
	_start_pulse()
	_start_bob()


func wiggle() -> void:
	var tw := create_tween()
	sticker.pivot_offset = sticker.size * 0.5
	var base := sticker.rotation_degrees
	for a in [8.0, -6.0, 4.0, 0.0]:
		tw.tween_property(sticker, "rotation_degrees", base + a, 0.07)


func _start_bob() -> void:
	if _bob:
		_bob.kill()
	miss_bubble.visible = missing
	if not missing:
		return
	var y := miss_bubble.position.y
	_bob = create_tween().set_loops()
	_bob.tween_property(miss_bubble, "position:y", y - 8.0, 0.6).set_trans(Tween.TRANS_SINE)
	_bob.tween_property(miss_bubble, "position:y", y, 0.6).set_trans(Tween.TRANS_SINE)


func _start_pulse() -> void:
	if _pulse:
		_pulse.kill()
	if not play_badge.visible:
		return
	play_badge.pivot_offset = play_badge.size * 0.5
	_pulse = create_tween().set_loops()
	_pulse.tween_property(play_badge, "scale", Vector2(1.15, 1.15), 0.5).set_trans(Tween.TRANS_SINE)
	_pulse.tween_property(play_badge, "scale", Vector2.ONE, 0.5).set_trans(Tween.TRANS_SINE)
