class_name LevelCard
extends Button

signal ev_selected(level_id: int)

@export var face_label: Label
@export var stars_label: Label
@export var lock_label: Label

var level_id: int = 1
var locked: bool = true

const EMOJI := {
	"bull": "🐂", "cat": "🐱", "dog": "🐶", "fox": "🦊",
	"lion": "🦁", "owl": "🦉", "duck": "🦆", "frog": "🐸",
	"fish": "🐟", "hedgehog": "🦔", "panda": "🐼", "deer": "🦌",
}


func _ready() -> void:
	custom_minimum_size = Vector2(140, 160)
	focus_mode = Control.FOCUS_NONE
	pressed.connect(_on_pressed)
	if face_label == null:
		face_label = get_node_or_null("VBox/Face") as Label
	if stars_label == null:
		stars_label = get_node_or_null("VBox/Stars") as Label
	if lock_label == null:
		lock_label = get_node_or_null("Lock") as Label
	_apply_chrome()


func setup(p_level_id: int, animal_id: String, stars: int, p_locked: bool) -> void:
	level_id = p_level_id
	locked = p_locked
	if face_label:
		face_label.text = str(EMOJI.get(animal_id, "🐾")) if not locked else "🔒"
	if stars_label:
		stars_label.text = "" if stars <= 0 else "★".repeat(stars)
	if lock_label:
		lock_label.visible = locked
	disabled = locked
	_apply_chrome()


func _apply_chrome() -> void:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color("FFD9B8") if not locked else Color("E8DCC8")
	sb.set_corner_radius_all(28)
	sb.set_border_width_all(4)
	sb.border_color = Color("E8B86D")
	sb.shadow_color = Color(0, 0, 0, 0.15)
	sb.shadow_size = 6
	sb.shadow_offset = Vector2(0, 4)
	add_theme_stylebox_override("normal", sb)
	add_theme_stylebox_override("hover", sb)
	add_theme_stylebox_override("pressed", sb)
	add_theme_stylebox_override("disabled", sb)


func _on_pressed() -> void:
	if not locked:
		ev_selected.emit(level_id)
