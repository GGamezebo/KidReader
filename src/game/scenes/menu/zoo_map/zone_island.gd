class_name ZoneIsland
extends Button

## Zone node on the zoo map: colored island with up to 3 animal stickers, name gate and 🐾 counter.
## LOCKED = fog + 🔒 (wiggles on tap), OPEN = pulsing ▶, READY = 🎪 festival available, DONE = 🏅.

signal ev_selected(island: ZoneIsland)

enum State { LOCKED, OPEN, READY, DONE }

@export var body: Control
@export var gate_label: Label
@export var paws_label: Label
@export var stickers: Array[PhotoSticker] = []
@export var badge: Control
@export var badge_label: Label
@export var medal: Control
@export var fog: Control

var zone: ZoneData
var state: State = State.LOCKED
var _pulse: Tween


func _ready() -> void:
	focus_mode = Control.FOCUS_NONE
	pressed.connect(_on_pressed)


## `photos`: textures of animals already living in the zone (first 3 are shown).
func setup(p_zone: ZoneData, p_state: State, cleared: int, photos: Array[Texture2D]) -> void:
	zone = p_zone
	state = p_state
	body.self_modulate = zone.color
	gate_label.text = "%s %s" % [zone.icon, zone.display_name]
	paws_label.text = "🐾 %d/%d" % [cleared, zone.levels.size()]
	paws_label.get_parent().visible = state != State.LOCKED
	for i in stickers.size():
		var has := i < photos.size()
		stickers[i].visible = has or state == State.OPEN
		stickers[i].setup(photos[i] if has else null, PhotoSticker.State.FILLED if has else PhotoSticker.State.EMPTY)
	fog.visible = state == State.LOCKED
	medal.visible = state == State.DONE
	badge.visible = state == State.OPEN or state == State.READY
	badge_label.text = "🎪" if state == State.READY else "▶"
	_start_pulse()


func wiggle() -> void:
	pivot_offset = size * 0.5
	var tw := create_tween()
	for a in [5.0, -4.0, 2.0, 0.0]:
		tw.tween_property(self, "rotation_degrees", a, 0.07)


func _on_pressed() -> void:
	if state == State.LOCKED:
		wiggle()
	else:
		ev_selected.emit(self)


func _start_pulse() -> void:
	if _pulse:
		_pulse.kill()
	if not badge.visible:
		return
	badge.pivot_offset = badge.size * 0.5
	_pulse = create_tween().set_loops()
	_pulse.tween_property(badge, "scale", Vector2(1.15, 1.15), 0.5).set_trans(Tween.TRANS_SINE)
	_pulse.tween_property(badge, "scale", Vector2.ONE, 0.5).set_trans(Tween.TRANS_SINE)
