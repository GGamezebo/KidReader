class_name CelebrationOverlay
extends Control

## Confetti + star fly-in + next-level CTA after word complete.

signal ev_next_pressed
signal ev_home_pressed

@export var stars_row: HBoxContainer
@export var confetti_host: Control
@export var next_button: Button
@export var home_button: Button
@export var title_label: Label

var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	visible = false
	mouse_filter = Control.MOUSE_FILTER_STOP
	_rng.randomize()
	if stars_row == null:
		stars_row = get_node_or_null("Center/StarsRow") as HBoxContainer
	if confetti_host == null:
		confetti_host = get_node_or_null("ConfettiHost") as Control
	if next_button == null:
		next_button = get_node_or_null("Center/NextButton") as Button
	if home_button == null:
		home_button = get_node_or_null("Center/HomeButton") as Button
	if title_label == null:
		title_label = get_node_or_null("Center/TitleLabel") as Label
	if next_button:
		next_button.pressed.connect(func(): ev_next_pressed.emit())
	if home_button:
		home_button.pressed.connect(func(): ev_home_pressed.emit())


func play(stars: int, animal_name: String) -> void:
	visible = true
	modulate = Color(1, 1, 1, 0)
	if title_label:
		title_label.text = animal_name
	_spawn_confetti()
	_show_stars(clampi(stars, 1, 3))
	var tw := create_tween()
	tw.tween_property(self, "modulate:a", 1.0, 0.25)
	if next_button:
		call_deferred("_pulse_next")


func set_has_next(has_next: bool) -> void:
	if next_button:
		next_button.visible = has_next
		next_button.text = "➜" if has_next else ""
	if home_button and not has_next:
		home_button.custom_minimum_size = Vector2(160, 96)


func _pulse_next() -> void:
	if next_button == null or not next_button.visible:
		return
	next_button.pivot_offset = next_button.size * 0.5
	var pulse := create_tween().set_loops()
	pulse.tween_property(next_button, "scale", Vector2(1.08, 1.08), 0.45)
	pulse.tween_property(next_button, "scale", Vector2.ONE, 0.45)


func _show_stars(count: int) -> void:
	if stars_row == null:
		return
	for c in stars_row.get_children():
		c.queue_free()
	for i in count:
		var star := Label.new()
		star.text = "★"
		star.add_theme_font_size_override("font_size", 72)
		star.add_theme_color_override("font_color", Color("FFC94A"))
		star.modulate.a = 0
		star.scale = Vector2(0.2, 0.2)
		stars_row.add_child(star)
		var tw := create_tween()
		tw.tween_interval(0.12 * i)
		tw.tween_property(star, "modulate:a", 1.0, 0.15)
		tw.parallel().tween_property(star, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK)


func _spawn_confetti() -> void:
	if confetti_host == null:
		return
	for c in confetti_host.get_children():
		c.queue_free()
	var colors := [Color("FF7A59"), Color("FFC94A"), Color("6BCB77"), Color("7EC8E8"), Color("F7D9E8")]
	for i in 40:
		var bit := ColorRect.new()
		bit.color = colors[i % colors.size()]
		bit.size = Vector2(_rng.randf_range(8, 16), _rng.randf_range(10, 22))
		bit.position = Vector2(size.x * 0.5, size.y * 0.35)
		confetti_host.add_child(bit)
		var dest := Vector2(_rng.randf_range(0, size.x), size.y + 40)
		var tw := create_tween()
		tw.set_parallel(true)
		tw.tween_property(bit, "position", dest, _rng.randf_range(0.8, 1.6))
		tw.tween_property(bit, "rotation", _rng.randf_range(-4, 4), 1.2)
		tw.tween_property(bit, "modulate:a", 0.0, 1.4)
		tw.chain().tween_callback(bit.queue_free)
