class_name AlbumEntry
extends Button

## One album slot: the animal's sticker + word sign when collected, an empty «?» frame otherwise.

signal ev_chosen(entry: AlbumEntry)

@export var sticker: PhotoSticker
@export var sign_plate: SignPlate

var level: LevelData
var collected: bool = false


func _ready() -> void:
	pressed.connect(func(): ev_chosen.emit(self))


func setup(p_level: LevelData, p_collected: bool) -> void:
	level = p_level
	collected = p_collected
	sticker.setup(level.animal_texture, PhotoSticker.State.FILLED if collected else PhotoSticker.State.EMPTY, level.emoji)
	sign_plate.setup(level.word, not collected)


func wiggle() -> void:
	pivot_offset = size * 0.5
	var tw := create_tween()
	for a in [6.0, -5.0, 3.0, 0.0]:
		tw.tween_property(self, "rotation_degrees", a, 0.07)
