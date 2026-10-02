@tool
class_name EnclosureFence
extends Control

## Procedural enclosure drawing (no art assets): wooden fence, ice blocks, glass dome, stone palisade.
## Covers the whole enclosure; draws the band at `band_top..band_bottom` (ratios of height) — dome also draws glass over the photo.

@export_enum("fence", "ice", "dome", "palisade") var style: String = "fence":
	set(v):
		style = v
		queue_redraw()
@export_range(0.0, 1.0) var band_top: float = 0.5
@export_range(0.0, 1.0) var band_bottom: float = 0.7
@export var wood: Color = Color("C98B52")
@export var wood_dark: Color = Color("8F5E33")
@export var ice_block: StyleBox
@export var stone: Color = Color("8A7B6E")
@export var stone_dark: Color = Color("6E6157")


func _ready() -> void:
	resized.connect(queue_redraw)


func _draw() -> void:
	var top := size.y * band_top
	var bottom := size.y * band_bottom
	match style:
		"ice":
			_draw_ice(top, bottom)
		"dome":
			_draw_dome(top, bottom)
		"palisade":
			_draw_palisade(top, bottom)
		_:
			_draw_fence(top, bottom)


func _draw_fence(top: float, bottom: float) -> void:
	var h := bottom - top
	for y in [top + h * 0.28, top + h * 0.66]:
		draw_rect(Rect2(-6, y, size.x + 12, h * 0.14), wood_dark)
	var post_w := 14.0
	var step := 24.0
	var x := 2.0
	while x < size.x - post_w + 3:
		var r := Rect2(x, top, post_w, h)
		draw_rect(r, wood)
		draw_rect(Rect2(x, top, post_w, 4), wood.lightened(0.25))
		draw_circle(Vector2(x + post_w * 0.5, top), post_w * 0.5, wood)
		x += step


func _draw_ice(top: float, bottom: float) -> void:
	var h := bottom - top
	var block := h * 0.5
	var rows := [[top + h * 0.5, 0.0], [top, block * 0.5]]
	for row in rows:
		var x: float = -block * 0.3 + row[1]
		while x < size.x:
			var r := Rect2(x + 2, row[0] + 2, block * 1.1 - 4, block - 4)
			if ice_block:
				draw_style_box(ice_block, r)
			draw_line(r.position + Vector2(6, 6), r.position + Vector2(r.size.x * 0.45, 6), Color(1, 1, 1, 0.9), 3.0)
			x += block * 1.1


func _draw_dome(top: float, bottom: float) -> void:
	# Glass dome over the photo + sandy base.
	var center := Vector2(size.x * 0.5, bottom - (bottom - top) * 0.55)
	var radius := size.x * 0.5
	var points := PackedVector2Array()
	for i in 33:
		var a := PI + PI * float(i) / 32.0
		points.append(center + Vector2(cos(a) * radius, sin(a) * radius * 1.25))
	points.append(Vector2(size.x, bottom))
	points.append(Vector2(0, bottom))
	draw_colored_polygon(points, Color(0.75, 0.93, 1.0, 0.18))
	draw_polyline(points.slice(0, 33), Color(1, 1, 1, 0.85), 5.0, true)
	draw_arc(center + Vector2(-radius * 0.35, -radius * 0.55), radius * 0.35, PI * 1.1, PI * 1.45, 12, Color(1, 1, 1, 0.7), 5.0, true)
	draw_rect(Rect2(-4, bottom - (bottom - top) * 0.35, size.x + 8, (bottom - top) * 0.35), Color("E9D39B"))


func _draw_palisade(top: float, bottom: float) -> void:
	var h := bottom - top
	var w := 18.0
	var x := 0.0
	var i := 0
	while x < size.x:
		var tip := top - (6.0 if i % 2 == 0 else 0.0)
		var poly := PackedVector2Array([
			Vector2(x, bottom), Vector2(x, tip + 12), Vector2(x + w * 0.5, tip), Vector2(x + w, tip + 12), Vector2(x + w, bottom)])
		draw_colored_polygon(poly, stone if i % 2 == 0 else stone_dark)
		x += w + 2
		i += 1
	draw_rect(Rect2(-4, top + h * 0.55, size.x + 8, 8), wood_dark)

