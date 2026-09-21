class_name AnimalView
extends Control

## Full-bleed realistic animal photo hidden behind frosted blur until word is complete.

@export var photo: TextureRect
@export var sparkles: Control
@export var blur_material: ShaderMaterial

var animal_id: String = "bull"
var _blur: float = 1.0
var _rng := RandomNumberGenerator.new()

const TEXTURE_BY_ID := {
	"bull": "res://assets/animals/animal_bull.jpg",
	"cat": "res://assets/animals/animal_cat.jpg",
	"dog": "res://assets/animals/animal_dog.jpg",
	"fox": "res://assets/animals/animal_fox.jpg",
	"lion": "res://assets/animals/animal_lion.jpg",
	"owl": "res://assets/animals/animal_owl.jpg",
	"duck": "res://assets/animals/animal_duck.jpg",
	"frog": "res://assets/animals/animal_frog.jpg",
	"fish": "res://assets/animals/animal_fish.jpg",
	"hedgehog": "res://assets/animals/animal_hedgehog.jpg",
	"panda": "res://assets/animals/animal_panda.jpg",
	"deer": "res://assets/animals/animal_deer.jpg",
}


func _ready() -> void:
	_rng.randomize()
	if photo == null:
		photo = get_node_or_null("Photo") as TextureRect
	if sparkles == null:
		sparkles = get_node_or_null("Sparkles") as Control
	if blur_material == null and photo and photo.material is ShaderMaterial:
		blur_material = photo.material as ShaderMaterial
	_spawn_ambient_sparkles()


func setup(p_animal_id: String, _display_name: String, texture: Texture2D = null) -> void:
	animal_id = p_animal_id
	_blur = 1.0
	if photo:
		if texture:
			photo.texture = texture
		else:
			photo.texture = _load_animal_texture(animal_id)
	_apply_blur()


func _load_animal_texture(id: String) -> Texture2D:
	var path: String = str(TEXTURE_BY_ID.get(id, TEXTURE_BY_ID["bull"]))
	if ResourceLoader.exists(path):
		var loaded := load(path)
		if loaded is Texture2D:
			return loaded as Texture2D
	# Fallback: decode image manually if import is missing/broken.
	if FileAccess.file_exists(path):
		var img := Image.new()
		var err := img.load(path)
		if err == OK:
			return ImageTexture.create_from_image(img)
	push_warning("AnimalView: failed to load texture for '%s' (%s)" % [id, path])
	return null


func set_progress(filled_ratio: float) -> void:
	## Softly ease blur as letters land; full clear on reveal().
	_blur = lerpf(1.0, 0.35, clampf(filled_ratio, 0.0, 1.0))
	_apply_blur()


func reveal() -> void:
	var tw := create_tween()
	tw.tween_method(_set_blur, _blur, 0.0, 0.55).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)


func set_happy() -> void:
	reveal()


func _set_blur(v: float) -> void:
	_blur = v
	_apply_blur()


func _apply_blur() -> void:
	if blur_material == null:
		return
	blur_material.set_shader_parameter("blur_strength", _blur)
	blur_material.set_shader_parameter("frost_amount", lerpf(0.0, 0.55, _blur))


func _spawn_ambient_sparkles() -> void:
	if sparkles == null:
		return
	for c in sparkles.get_children():
		c.queue_free()
	for i in 12:
		var star := Label.new()
		star.text = "✦"
		star.add_theme_font_size_override("font_size", _rng.randi_range(14, 28))
		star.add_theme_color_override("font_color", Color(1, 1, 1, _rng.randf_range(0.35, 0.85)))
		star.mouse_filter = Control.MOUSE_FILTER_IGNORE
		sparkles.add_child(star)
		star.position = Vector2(_rng.randf_range(40, 1200), _rng.randf_range(40, 600))
		var tw := create_tween().set_loops()
		tw.tween_property(star, "modulate:a", 0.15, _rng.randf_range(0.6, 1.4))
		tw.tween_property(star, "modulate:a", 1.0, _rng.randf_range(0.6, 1.4))
