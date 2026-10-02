class_name AlbumZone
extends VBoxContainer

## Album section for one zone: header pill (icon, name, 🐾 n/m, 🔒 when closed) + a flow of AlbumEntry slots.

signal ev_entry_chosen(entry: AlbumEntry)

@export var entry_scene: PackedScene
@export var title_label: Label
@export var count_label: Label
@export var lock_label: Control
@export var grid: HFlowContainer


func setup(zone: ZoneData, progress: ZooProgress) -> void:
	title_label.text = "%s  %s" % [zone.icon, zone.display_name]
	count_label.text = "🐾 %d/%d" % [progress.cleared_count(zone), zone.levels.size()]
	lock_label.visible = not progress.is_zone_unlocked(zone)
	for child in grid.get_children():
		child.queue_free()
	for level in zone.levels:
		var entry := entry_scene.instantiate() as AlbumEntry
		grid.add_child(entry)
		entry.setup(level, progress.is_level_cleared(level.level_id))
		entry.ev_chosen.connect(func(e: AlbumEntry): ev_entry_chosen.emit(e))
