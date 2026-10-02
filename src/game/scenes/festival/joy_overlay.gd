class_name JoyOverlay
extends Control

## Festival won: fireworks (procedural), medal with the zone icon, stars fill one by one,
## the zone's animals dance, the next zone's card shows an opened lock. ▶ continues to the map.

signal ev_continue

@export var sticker_scene: PackedScene
@export var fireworks: Control
@export var medal: Control
@export var medal_icon: Label
@export var stars: Array[Label] = []
@export var star_on: Color = Color("FFC94A")
@export var star_off: Color = Color(1, 1, 1, 0.55)
@export var dancers: HBoxContainer
@export var next_zone: Control
@export var next_zone_label: Label
@export var continue_button: BaseButton
@export var burst_colors: Array[Color] = [Color("FFC94A"), Color("E53935"), Color("73C76B"), Color("8CC7F2")]

var _time: float = 0.0
var _dance: Array[Tween] = []


func _ready() -> void:
	visible = false
	set_process(false)
	fireworks.draw.connect(_draw_fireworks)
	continue_button.pressed.connect(func(): ev_continue.emit())


func play(zone: ZoneData, star_count: int, next: ZoneData) -> void:
	visible = true
	set_process(true)
	medal_icon.text = zone.icon
	for star in stars:
		star.modulate = star_off
	next_zone.visible = next != null
	if next:
		next_zone_label.text = "%s %s  🔓" % [next.icon, next.display_name]
	continue_button.visible = false
	for child in dancers.get_children():
		child.queue_free()
	for level in zone.levels.slice(0, 7):
		var s := sticker_scene.instantiate() as PhotoSticker
		s.custom_minimum_size = Vector2(110, 110)
		s.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		dancers.add_child(s)
		s.setup(level.animal_texture, PhotoSticker.State.FILLED, level.emoji)

	medal.pivot_offset = medal.size * 0.5
	medal.scale = Vector2.ZERO
	var tw := create_tween()
	tw.tween_property(medal, "scale", Vector2.ONE, 0.6).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	for i in stars.size():
		if i < star_count:
			var star := stars[i]
			star.pivot_offset = star.size * 0.5
			tw.tween_property(star, "modulate", star_on, 0.01)
			tw.tween_property(star, "scale", Vector2(1.5, 1.5), 0.12)
			tw.tween_property(star, "scale", Vector2.ONE, 0.18)
	await tw.finished
	_start_dance()
	continue_button.visible = true
	continue_button.pivot_offset = continue_button.size * 0.5
	var pulse := create_tween().set_loops()
	pulse.tween_property(continue_button, "scale", Vector2(1.12, 1.12), 0.5).set_trans(Tween.TRANS_SINE)
	pulse.tween_property(continue_button, "scale", Vector2.ONE, 0.5).set_trans(Tween.TRANS_SINE)


func _start_dance() -> void:
	var i := 0
	for d in dancers.get_children():
		var c := d as Control
		c.pivot_offset = c.size * 0.5
		var tw := create_tween().set_loops()
		tw.tween_interval(0.08 * i)
		tw.tween_property(c, "rotation_degrees", 8.0, 0.3).set_trans(Tween.TRANS_SINE)
		tw.tween_property(c, "rotation_degrees", -8.0, 0.3).set_trans(Tween.TRANS_SINE)
		_dance.append(tw)
		i += 1


func _process(delta: float) -> void:
	_time += delta
	fireworks.queue_redraw()


## Bursts at fixed spots, each on its own 1.6 s cycle: rays grow and fade.
func _draw_fireworks() -> void:
	var w := fireworks.size.x
	var h := fireworks.size.y
	var spots := [Vector2(0.15, 0.25), Vector2(0.85, 0.22), Vector2(0.3, 0.6), Vector2(0.72, 0.58)]
	for i in spots.size():
		var t := fmod(_time + i * 0.4, 1.6) / 1.6
		var center: Vector2 = spots[i] * Vector2(w, h)
		var color: Color = burst_colors[i % burst_colors.size()]
		color.a = 1.0 - t
		for k in 12:
			var dir := Vector2.from_angle(TAU * k / 12.0)
			fireworks.draw_line(center + dir * 70.0 * t, center + dir * 150.0 * t, color, 6.0, true)
