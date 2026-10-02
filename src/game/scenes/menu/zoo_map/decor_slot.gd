class_name DecorSlot
extends DecorPiece

## One decoration in the park box. LOCKED = dark silhouette + ⭐ needed (tap wiggles),
## READY = full colour, drag it onto the map, PLACED = faded with ✓ (it is on the map).

enum State { LOCKED, READY, PLACED }

@export var stars_label: Label
@export var placed_mark: Control
@export var locked_tint: Color = Color(0.25, 0.2, 0.2, 0.55)

var state: State = State.LOCKED


func setup_slot(p_item: DecorItem, p_state: State) -> void:
	setup(p_item)
	state = p_state
	draggable = state == State.READY
	stars_label.visible = state == State.LOCKED
	stars_label.text = "⭐ %d" % item.stars
	placed_mark.visible = state == State.PLACED
	glyph_label.modulate = locked_tint if state == State.LOCKED else Color(1, 1, 1, 0.4 if state == State.PLACED else 1.0)
