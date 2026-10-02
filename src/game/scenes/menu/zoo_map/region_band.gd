class_name RegionBand
extends Control

## Background stretch of the zoo map for one region: vertical gradient from RegionData colors,
## procedural decor (bushes on land, bubbles under water), title pill and the transition icon to the next region.

@export var bg: TextureRect
@export var decor: Control
@export var title_label: Label
@export var hop_label: Label

var region: RegionData
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	decor.draw.connect(_draw_decor)
	resized.connect(decor.queue_redraw)


func setup(p_region: RegionData) -> void:
	region = p_region
	var tex := bg.texture.duplicate(true) as GradientTexture2D
	tex.gradient.set_color(0, region.color_top)
	tex.gradient.set_color(1, region.color_bottom)
	bg.texture = tex
	title_label.text = "%s %s" % [region.icon, region.display_name]
	hop_label.text = region.transition_icon
	hop_label.visible = not region.transition_icon.is_empty()
	decor.queue_redraw()


func _draw_decor() -> void:
	if region == null:
		return
	_rng.seed = hash(region.region_id)
	var w := decor.size.x
	var h := decor.size.y
	var underwater := region.enclosure_style == "dome"
	var count := int(w / 70.0)
	for i in count:
		var p := Vector2(_rng.randf_range(0.0, w), _rng.randf_range(h * 0.15, h * 0.98))
		var r := _rng.randf_range(10.0, 34.0)
		if underwater:
			decor.draw_arc(p, r * 0.6, 0.0, TAU, 24, Color(1, 1, 1, 0.35), 3.0, true)
		else:
			decor.draw_circle(p, r, Color(region.color_bottom.darkened(0.18), 0.45))
