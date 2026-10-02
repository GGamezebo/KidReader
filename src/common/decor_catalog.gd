class_name DecorCatalog
extends Resource

## Park decorations in unlock order (`DecorItem.stars` ascending). Hand-edited `decor_catalog.tres`.

@export var items: Array[DecorItem] = []


func get_item(decor_id: String) -> DecorItem:
	for item in items:
		if item and item.decor_id == decor_id:
			return item
	return null
