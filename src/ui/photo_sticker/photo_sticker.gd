@tool
class_name PhotoSticker
extends Control

## Die-cut photo sticker: white rounded frame + photo. One component for map, enclosures, festival cards.
## FILLED = clear photo, FROST = frosted blur + «?» (the next animal), EMPTY = dashed-like blank frame + «?».

enum State { FILLED, FROST, EMPTY }

@export var texture: Texture2D:
	set(v):
		texture = v
		_refresh()
@export var state: State = State.FILLED:
	set(v):
		state = v
		_refresh()
## Frame thickness relative to the shorter side, so the same scene works from 60 to 300 px.
@export_range(0.0, 0.2) var frame_ratio: float = 0.055
## Shown when FILLED but the animal has no photo yet.
@export var placeholder_texture: Texture2D
@export var placeholder_glyph: String = "🐾"

@export_group("Nodes")
@export var frame: Panel
@export var mask: Panel
@export var photo: TextureRect
@export var question: Label
@export var glyph: Label

@export_group("Styles")
@export var frame_style: StyleBox
@export var empty_style: StyleBox


func _ready() -> void:
	resized.connect(_layout)
	_layout()
	_refresh()


func setup(p_texture: Texture2D, p_state: State) -> void:
	texture = p_texture
	state = p_state


## 1 = fully frosted, 0 = clear. For reveal animations (tween this method); FROST state sets 1.
func set_frost(amount: float) -> void:
	var mat := photo.material as ShaderMaterial if photo else null
	if mat:
		mat.set_shader_parameter("blur_strength", amount)
	if question and state == State.FROST:
		question.modulate.a = clampf(amount * 2.0 - 1.0, 0.0, 1.0)


func _layout() -> void:
	if mask == null:
		return
	var inset := minf(size.x, size.y) * frame_ratio
	mask.offset_left = inset
	mask.offset_top = inset
	mask.offset_right = -inset
	mask.offset_bottom = -inset
	var font := int(minf(size.x, size.y) * 0.42)
	if question:
		question.add_theme_font_size_override("font_size", font)
	if glyph:
		glyph.add_theme_font_size_override("font_size", int(font * 0.8))


func _refresh() -> void:
	if not is_node_ready():
		return
	var empty := state == State.EMPTY
	if frame:
		frame.add_theme_stylebox_override("panel", empty_style if empty else frame_style)
	var shown := texture if texture else placeholder_texture
	if photo:
		photo.visible = not empty
		photo.texture = shown
		var mat := photo.material as ShaderMaterial
		if mat:
			mat.set_shader_parameter("blur_strength", 1.0 if state == State.FROST else 0.0)
	if mask:
		mask.self_modulate.a = 0.0 if empty else 1.0
	if question:
		question.visible = state != State.FILLED
		question.modulate.a = 1.0
	if glyph:
		glyph.visible = state == State.FILLED and texture == null
		glyph.text = placeholder_glyph
