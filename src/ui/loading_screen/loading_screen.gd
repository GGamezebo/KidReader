extends CanvasLayer

@export var progress_bar: ProgressBar
@export var background: CanvasGroup

const duration: float = 0.7


func _ready() -> void:
	get_viewport().size_changed.connect(_fit_to_viewport)
	call_deferred("_fit_to_viewport")


func update_progress(value: float) -> void:
	if progress_bar:
		progress_bar.value = value * 100.0


func fade_out() -> void:
	var tween := create_tween()
	tween.set_parallel(true)
	var slide := -get_viewport().get_visible_rect().size.y
	tween.tween_property(self, "offset:y", slide, duration).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	if background:
		tween.tween_property(background, "modulate:a", 0.0, duration)
	tween.finished.connect(queue_free)


func _fit_to_viewport() -> void:
	if background == null:
		return
	var vp := get_viewport().get_visible_rect().size
	for child in background.get_children():
		if child is ColorRect:
			var rect := child as Control
			rect.set_anchors_preset(Control.PRESET_FULL_RECT)
			rect.size = vp
