class_name HandHint
extends Control

## Animated 👆 that shows a pre-reader what to do, no text: tap a control, or drag one onto another.
## The fingertip sits at this node's origin; targets are re-read every frame (works over floating
## tiles and scrolling screens). Loops until stop(). Never takes input.

## The 👆 glyph, placed so its fingertip is at the origin.
@export var hand: Control
## Ripple around the fingertip on a press.
@export var ring: Control
## Ghost of the dragged thing rides here (centered on the fingertip).
@export var carry_host: Control
@export var drag_sec: float = 1.1
@export var pause_sec: float = 0.7

## 0 = at `_from`, 1 = at `_to` (tweened while dragging).
var travel: float = 0.0
var _from: Control
var _to: Control
var _loop: Tween


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hide()


## Loops a press on `target`'s center.
func tap(target: Control) -> void:
	if _from == target and _to == target and visible:
		return
	_begin(target, target, null)
	_loop = create_tween().set_loops()
	_loop.tween_property(hand, "modulate:a", 1.0, 0.2)
	_press(_loop)
	_release(_loop)
	_loop.tween_interval(0.15)
	_press(_loop)
	_release(_loop)
	_loop.tween_property(hand, "modulate:a", 0.0, 0.25).set_delay(0.3)
	_loop.tween_interval(pause_sec)


## Loops: press on `from`, carry `carry` (a ghost the caller made; freed on stop) to `to`, let go.
func drag(from: Control, to: Control, carry: Control = null) -> void:
	_begin(from, to, carry)
	_loop = create_tween().set_loops()
	_loop.tween_callback(func(): travel = 0.0)
	_loop.tween_property(hand, "modulate:a", 1.0, 0.25)
	_press(_loop)
	_loop.tween_property(carry_host, "modulate:a", 0.75, 0.12)
	_loop.tween_property(self, "travel", 1.0, drag_sec).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_release(_loop)
	_loop.tween_property(carry_host, "modulate:a", 0.0, 0.25)
	_loop.parallel().tween_property(hand, "modulate:a", 0.0, 0.3)
	_loop.tween_interval(pause_sec)


func stop() -> void:
	_hide()


func _begin(from: Control, to: Control, carry: Control) -> void:
	_hide()
	_from = from
	_to = to
	travel = 0.0
	if carry:
		carry_host.add_child(carry)
		carry.mouse_filter = Control.MOUSE_FILTER_IGNORE
		carry.position = -carry.size * 0.5
	visible = true
	set_process(true)
	_process(0.0)


func _press(tw: Tween) -> void:
	tw.tween_property(hand, "scale", Vector2(0.82, 0.82), 0.15).set_trans(Tween.TRANS_SINE)
	tw.parallel().tween_property(ring, "modulate:a", 0.9, 0.1)
	tw.parallel().tween_property(ring, "scale", Vector2.ONE * 1.3, 0.35).from(Vector2.ONE * 0.5)


func _release(tw: Tween) -> void:
	tw.tween_property(hand, "scale", Vector2.ONE, 0.15).set_trans(Tween.TRANS_BACK)
	tw.parallel().tween_property(ring, "modulate:a", 0.0, 0.2)


func _hide() -> void:
	if _loop:
		_loop.kill()
		_loop = null
	_from = null
	_to = null
	visible = false
	set_process(false)
	hand.modulate.a = 0.0
	hand.scale = Vector2.ONE
	ring.modulate.a = 0.0
	carry_host.modulate.a = 0.0
	for child in carry_host.get_children():
		child.queue_free()


func _process(_delta: float) -> void:
	if not is_instance_valid(_from) or not is_instance_valid(_to):
		_hide()
		return
	var a := _from.get_global_rect().get_center()
	var b := _to.get_global_rect().get_center()
	global_position = a.lerp(b, travel)
