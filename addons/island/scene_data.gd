@tool
class_name IslandSceneData
extends Resource

@export var enabled: bool = true

@export var layer: int = 0:
	set(value):
		layer = max(0, value)

@export var scene: PackedScene:
	set(value):
		scene = value
		if scene and scene.resource_path:
			resource_name = scene.resource_path.get_file().get_basename()

@export var z_index: int
@export var spacing: Vector2i = Vector2i(1, 1):
	set(value):
		spacing = Vector2i(max(1, value.x), max(1, value.y))
		
## Сreation on another scene
@export var prevent_on_other: bool = true

## Noise tile placement
@export var noise: IslandNoiseInfo

@export_group("Thresholds")

## The minimum threshold
@export_range(0, 1) var minimum: float = 0:
	set(value):
		minimum = value
		if minimum > maximum:
			maximum = minimum
		emit_changed()

## The maximum threshold
@export_range(0, 1) var maximum: float = 1:
	set(value):
		maximum = value
		if maximum < minimum:
			minimum = maximum
		emit_changed()
