class_name Platform
extends RefCounted

## The one place for OS feature checks (see "Target platforms" in CLAUDE.md).


## Running from the Godot editor (F5/F6), never in an exported build.
static func is_editor() -> bool:
	return OS.has_feature("editor")
