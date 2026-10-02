class_name ZoneIsland
extends Button

## Zone node on the zoo map: colored island with up to 3 animal stickers, name gate and 🐾 counter.
## LOCKED = fog + 🔒 (wiggles on tap), OPEN = pulsing ▶, READY = 🎪 festival available, DONE = 🏅.
## 💭 = an animal of this zone misses the child (see ZooProgress.review_in_zone).

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
@export var miss_bubble: Control

var zone: ZoneData
var state: State = State.LOCKED
var _pulse: Tween


func _ready() -> void:
	focus_mode = Control.FOCUS_NONE
	pressed.connect(_on_pressed)


## `animals`: animals already living in the zone (first 3 are shown as stickers).
func setup(p_zone: ZoneData, p_state: State, cleared: int, animals: Array[LevelData], missing: bool = false) -> void:
	zone = p_zone
	state = p_state
	body.self_modulate = zone.color
	gate_label.text = "%s %s" % [zone.icon, zone.display_name]
	paws_label.text = "🐾 %d/%d" % [cleared, zone.levels.size()]
	paws_label.get_parent().visible = state != State.LOCKED
	for i in stickers.size():
		var has := i < animals.size()
		stickers[i].visible = has or state == State.OPEN
		if has:
			stickers[i].setup(animals[i].animal_texture, PhotoSticker.State.FILLED, animals[i].emoji)
		else:
			stickers[i].setup(null, PhotoSticker.State.EMPTY)
	fog.visible = state == State.LOCKED
	medal.visible = state == State.DONE
	miss_bubble.visible = missing and state != State.LOCKED
	badge.visible = state == State.OPEN or state == State.READY
	badge_label.text = "🎪" if state == State.READY else "▶"
	_start_pulse()


func wiggle() -> void:
	pivot_offset = size * 0.5
	var tw := create_tween()
	for a in [5.0, -4.0, 2.0, 0.0]:
		tw.tween_property(self, "rotation_degrees", a, 0.07)


## Zone just opened by a festival: fog + lock shown, then the lock pops and the fog melts away.
func play_unlock() -> void:
	fog.visible = true
	fog.modulate.a = 1.0
	var lock := fog.get_child(0) as Control
	lock.pivot_offset = lock.size * 0.5
	pivot_offset = size * 0.5
	var tw := create_tween()
	tw.tween_interval(0.5)
	tw.tween_property(lock, "scale", Vector2(1.6, 1.6), 0.25).set_trans(Tween.TRANS_BACK)
	tw.parallel().tween_property(lock, "rotation_degrees", 25.0, 0.25)
	tw.tween_property(fog, "modulate:a", 0.0, 0.6)
	tw.tween_property(self, "scale", Vector2(1.12, 1.12), 0.15)
	tw.tween_property(self, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BOUNCE)
	await tw.finished
	fog.visible = false
	lock.scale = Vector2.ONE
	lock.rotation_degrees = 0.0


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
