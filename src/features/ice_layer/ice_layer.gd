class_name IceLayer
extends Control

## Ice overlay over the animal. Cracks as progress rises; shatters at 1.0.

@export var ice_panel: Panel
@export var crack_lines: Control
@export var shards_host: Control

var progress: float = 0.0
var _shard_rng := RandomNumberGenerator.new()


func _ready() -> void:
	if ice_panel == null:
		ice_panel = get_node_or_null("IcePanel") as Panel
	if crack_lines == null:
		crack_lines = get_node_or_null("Cracks") as Control
	if shards_host == null:
		shards_host = get_node_or_null("Shards") as Control
	_shard_rng.randomize()
	_rebuild_style()
	_clear_cracks()


func reset() -> void:
	progress = 0.0
	visible = true
	modulate = Color.WHITE
	scale = Vector2.ONE
	if ice_panel:
		ice_panel.scale = Vector2.ONE
		ice_panel.modulate = Color.WHITE
	_clear_cracks()
	_rebuild_style()
	if shards_host:
		for c in shards_host.get_children():
			c.queue_free()


func set_progress(p: float) -> void:
	var prev := progress
	progress = clampf(p, 0.0, 1.0)
	_rebuild_style()
	_rebuild_cracks()
	if progress > prev and ice_panel:
		ice_panel.pivot_offset = ice_panel.size * 0.5
		var tw := create_tween()
		tw.tween_property(ice_panel, "scale", Vector2(1.06, 1.06), 0.06)
		tw.tween_property(ice_panel, "scale", Vector2.ONE, 0.12)


func shatter() -> void:
	_spawn_shards()
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(ice_panel, "modulate", Color(1, 1, 1, 0), 0.28)
	tw.tween_property(self, "scale", Vector2(1.15, 1.15), 0.28)
	tw.chain().tween_callback(func(): visible = false)


func _rebuild_style() -> void:
	if ice_panel == null:
		return
	var sb := StyleBoxFlat.new()
	var alpha := lerpf(0.72, 0.25, progress)
	sb.bg_color = Color(0.72, 0.9, 0.98, alpha)
	sb.set_corner_radius_all(88)
	sb.set_border_width_all(6)
	sb.border_color = Color(0.85, 0.95, 1.0, 0.9)
	ice_panel.add_theme_stylebox_override("panel", sb)


func _clear_cracks() -> void:
	if crack_lines == null:
		return
	for c in crack_lines.get_children():
		c.queue_free()


func _rebuild_cracks() -> void:
	_clear_cracks()
	if crack_lines == null or progress <= 0.0:
		return
	var count := int(ceil(progress * 8.0))
	var center := size * 0.5
	if center == Vector2.ZERO:
		center = Vector2(110, 110)
	for i in count:
		var line := ColorRect.new()
		line.color = Color(1, 1, 1, 0.85)
		var length := 28.0 + float(i) * 16.0
		line.size = Vector2(length, 3.5)
		line.pivot_offset = Vector2(0, 1.5)
		line.position = center
		line.rotation = deg_to_rad(-40.0 + float(i) * 28.0)
		crack_lines.add_child(line)


func _spawn_shards() -> void:
	if shards_host == null:
		return
	for i in 14:
		var shard := ColorRect.new()
		shard.color = Color(0.75, 0.92, 1.0, 0.95)
		shard.size = Vector2(_shard_rng.randf_range(12, 28), _shard_rng.randf_range(8, 18))
		shard.position = size * 0.5
		shards_host.add_child(shard)
		var dir := Vector2.from_angle(_shard_rng.randf_range(0, TAU)) * _shard_rng.randf_range(120, 260)
		var tw := create_tween()
		tw.set_parallel(true)
		tw.tween_property(shard, "position", shard.position + dir, 0.55)
		tw.tween_property(shard, "modulate:a", 0.0, 0.55)
		tw.tween_property(shard, "rotation", _shard_rng.randf_range(-2, 2), 0.55)
		tw.chain().tween_callback(shard.queue_free)
