class_name DinoEgg
extends Button

## Dino egg in its nest (zoo map corner): a months-long goal visible from day one.
## Mystery (dark silhouette + «?») → found: one more crack per festival → hatched: a baby dino in the shell.
## State is derived by ZooProgress (egg_cracks / is_egg_hatched); nothing is saved.
## Egg, spots, cracks and nest are drawn procedurally; «?» and the baby are scene nodes.

@export var voice_bank: VoiceBank
@export var voice_player: AudioStreamPlayer

@export_group("Nodes")
@export var nest_back: Control
@export var shell: Control
@export var nest_front: Control
@export var mystery: Control
@export var baby: Control

@export_group("Look")
@export var egg_color: Color = Color("FFF4DC")
@export var egg_outline: Color = Color("D9C29A")
@export var spot_color: Color = Color("B9D77E")
@export var crack_color: Color = Color("6B4A2B")
@export var nest_color: Color = Color("A0703F")
@export var nest_dark: Color = Color("7A5230")
@export var mystery_tint: Color = Color(0.45, 0.4, 0.38)

@export_group("F6 preview")
@export var preview_cracks: int = 3
@export var preview_max: int = 11

## -1 = not found yet.
var cracks: int = -1
var max_cracks: int = 11
var hatched: bool = false
var _has_setup: bool = false

## Spots on the shell: (x, y, radius) as shares of the egg half-axes.
const SPOTS: Array[Vector3] = [
	Vector3(-0.38, -0.32, 0.13), Vector3(0.3, -0.08, 0.16), Vector3(-0.12, 0.34, 0.11),
	Vector3(0.42, 0.42, 0.08), Vector3(-0.5, 0.14, 0.08), Vector3(0.08, -0.62, 0.09),
]


func _ready() -> void:
	nest_back.draw.connect(_draw_nest_back)
	shell.draw.connect(_draw_shell)
	nest_front.draw.connect(_draw_nest_front)
	pressed.connect(_on_pressed)
	_preview.call_deferred()


func _preview() -> void:
	if not _has_setup:
		setup(preview_cracks, preview_max, false)


func setup(p_cracks: int, p_max: int, p_hatched: bool) -> void:
	_has_setup = true
	cracks = p_cracks
	max_cracks = maxi(1, p_max)
	hatched = p_hatched
	var hidden := cracks < 0 and not hatched
	mystery.visible = hidden
	mystery.modulate.a = 1.0
	shell.modulate = mystery_tint if hidden else Color.WHITE
	baby.visible = hatched
	baby.scale = Vector2.ONE
	shell.queue_redraw()


## Home region done: the mystery silhouette turns into a real egg.
func play_found() -> void:
	await _shake(3, 6.0)
	var tw := create_tween()
	tw.tween_property(mystery, "modulate:a", 0.0, 0.3)
	tw.parallel().tween_property(shell, "modulate", Color.WHITE, 0.6)
	await tw.finished
	cracks = 0
	mystery.visible = false
	await _bounce()
	_say("egg_found")


## One more festival: the egg trembles and gets a new crack.
func play_crack() -> void:
	await _shake(4, 8.0)
	cracks = mini(cracks + 1, max_cracks)
	shell.queue_redraw()
	await _bounce()
	_say("egg_crack")


## The dino zone opens: strong shake, the top flies off, the baby pops out.
func play_hatch() -> void:
	await _shake(6, 12.0)
	hatched = true
	cracks = max_cracks
	shell.queue_redraw()
	baby.visible = true
	baby.pivot_offset = baby.size * Vector2(0.5, 1.0)
	baby.scale = Vector2.ZERO
	var tw := create_tween()
	tw.tween_property(baby, "scale", Vector2.ONE, 0.5).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	await tw.finished
	_say("egg_hatched")
	await _hop()


func _on_pressed() -> void:
	if hatched:
		_say("egg_hatched")
		_hop()
	elif cracks < 0:
		_say("egg_mystery")
		_shake(2, 5.0)
	else:
		_say("egg_wait")
		_shake(2, 5.0 + cracks)


func _shake(times: int, degrees: float) -> void:
	pivot_offset = size * Vector2(0.5, 0.9)
	var tw := create_tween()
	for i in times:
		tw.tween_property(self, "rotation_degrees", degrees, 0.06)
		tw.tween_property(self, "rotation_degrees", -degrees, 0.08)
	tw.tween_property(self, "rotation_degrees", 0.0, 0.06)
	await tw.finished


func _bounce() -> void:
	pivot_offset = size * Vector2(0.5, 0.9)
	var tw := create_tween()
	tw.tween_property(self, "scale", Vector2(1.15, 1.15), 0.15)
	tw.tween_property(self, "scale", Vector2.ONE, 0.3).set_trans(Tween.TRANS_BOUNCE)
	await tw.finished


func _hop() -> void:
	var y := baby.position.y
	var tw := create_tween()
	for i in 2:
		tw.tween_property(baby, "position:y", y - 18.0, 0.15).set_ease(Tween.EASE_OUT)
		tw.tween_property(baby, "position:y", y, 0.15).set_ease(Tween.EASE_IN)
	await tw.finished


func _say(key: String) -> void:
	var stream := voice_bank.get_phrase(key) if voice_bank else null
	if stream and voice_player:
		voice_player.stream = stream
		voice_player.play()


func _egg_axes() -> Array:
	var c := shell.size * Vector2(0.5, 0.52)
	return [c, shell.size.x * 0.34, shell.size.y * 0.4]


func _egg_point(c: Vector2, rx: float, ry: float, t: float) -> Vector2:
	# Narrower top: an egg, not an ellipse.
	return c + Vector2(rx * sin(t) * (1.0 - 0.14 * cos(t)), -ry * cos(t))


func _draw_shell() -> void:
	var a := _egg_axes()
	var c: Vector2 = a[0]
	var rx: float = a[1]
	var ry: float = a[2]
	var pts := PackedVector2Array()
	if hatched:
		# Lower half with a zigzag broken edge.
		for i in 25:
			pts.append(_egg_point(c, rx, ry, PI * 0.5 + PI * i / 24.0))
		for k in range(1, 8):
			var x := -rx + 2.0 * rx * k / 8.0
			pts.append(c + Vector2(x, -ry * 0.16 if k % 2 == 1 else 0.0))
	else:
		for i in 48:
			pts.append(_egg_point(c, rx, ry, TAU * i / 48.0))
	shell.draw_colored_polygon(pts, egg_color)
	for s in SPOTS:
		if hatched and s.y < 0.1:
			continue
		shell.draw_circle(c + Vector2(s.x * rx, s.y * ry), s.z * rx * 2.0, spot_color)
	var outline := pts.duplicate()
	outline.append(pts[0])
	shell.draw_polyline(outline, egg_outline, 3.0, true)
	if not hatched:
		_draw_cracks(c, rx, ry)


## Each crack is a short seeded zigzag, so the egg looks the same every time.
func _draw_cracks(c: Vector2, rx: float, ry: float) -> void:
	var rng := RandomNumberGenerator.new()
	for i in maxi(cracks, 0):
		rng.seed = 1000 + i * 7919
		var p := c + Vector2(rng.randf_range(-0.5, 0.5) * rx, rng.randf_range(-0.55, 0.45) * ry)
		var line := PackedVector2Array([p])
		var angle := rng.randf_range(0.0, TAU)
		for k in 4:
			angle += rng.randf_range(-1.0, 1.0)
			var next := p + Vector2.from_angle(angle) * rng.randf_range(8.0, 13.0)
			if ((next - c) / Vector2(rx, ry)).length() > 0.85:
				break
			line.append(next)
			p = next
		if line.size() > 1:
			shell.draw_polyline(line, crack_color, 3.0, true)


func _draw_nest_back() -> void:
	var s := nest_back.size
	nest_back.draw_set_transform(Vector2(s.x * 0.5, s.y * 0.8), 0.0, Vector2(1.0, 0.32))
	nest_back.draw_circle(Vector2.ZERO, s.x * 0.46, nest_dark)
	nest_back.draw_set_transform_matrix(Transform2D.IDENTITY)


func _draw_nest_front() -> void:
	var s := nest_front.size
	var c := Vector2(s.x * 0.5, s.y * 0.8)
	var rx := s.x * 0.48
	var ry := s.y * 0.17
	var bowl := PackedVector2Array()
	for i in 17:
		var t := PI * i / 16.0
		bowl.append(c + Vector2(rx * cos(t), ry * sin(t) + ry * 0.2))
	bowl.append(c + Vector2(-rx, -ry * 0.1))
	bowl.append(c + Vector2(rx, -ry * 0.1))
	nest_front.draw_colored_polygon(bowl, nest_color)
	# Twigs across the bowl.
	for k in 6:
		var y := c.y + ry * (0.05 + 0.18 * k)
		var w := rx * (1.0 - 0.12 * k)
		nest_front.draw_line(Vector2(c.x - w, y), Vector2(c.x + w * 0.8, y + 4.0), nest_dark, 2.5, true)
