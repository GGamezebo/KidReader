class_name FestivalCard
extends Button

## One answer card of a festival round: the animal's photo sticker (or emoji placeholder). No word on it —
## the child matches the word on the sign to the picture.

signal ev_chosen(card: FestivalCard)

@export var sticker: PhotoSticker

var level: LevelData


func _ready() -> void:
	focus_mode = Control.FOCUS_NONE
	pressed.connect(func(): ev_chosen.emit(self))


func setup(p_level: LevelData, side: float) -> void:
	level = p_level
	custom_minimum_size = Vector2(side, side)
	sticker.setup(level.animal_texture, PhotoSticker.State.FILLED, level.emoji)
	sticker.rotation_degrees = [-4.0, 2.0, -2.0, 3.0, -3.0, 4.0][absi(level.level_id) % 6]


## Wrong pick: soft wiggle, then the card fades and can't be picked again this round.
func reject() -> void:
	disabled = true
	sticker.pivot_offset = sticker.size * 0.5
	var base := sticker.rotation_degrees
	var tw := create_tween()
	for a in [9.0, -7.0, 5.0, 0.0]:
		tw.tween_property(sticker, "rotation_degrees", base + a, 0.07)
	tw.tween_property(self, "modulate", Color(1, 1, 1, 0.4), 0.25)


## Right pick: happy hop.
func celebrate() -> void:
	pivot_offset = size * 0.5
	var tw := create_tween()
	tw.tween_property(self, "scale", Vector2(1.15, 1.15), 0.15).set_trans(Tween.TRANS_BACK)
	tw.tween_property(self, "position:y", position.y - 30.0, 0.15)
	tw.tween_property(self, "position:y", position.y, 0.25).set_trans(Tween.TRANS_BOUNCE)
	tw.tween_property(self, "scale", Vector2.ONE, 0.15)
