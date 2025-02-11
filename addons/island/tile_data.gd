@tool
class_name IslandTileData
extends Resource

@export var enabled: bool = true
@export var title: String = "":
	set(value):
		title = value
		resource_name = title

## Data on which tile to take
@export var tile_info: IslandTileMapLayerTileInfo = IslandTileMapLayerTileInfo.new()

## Not to create on another tile for all TileMapLayer
@export var prevent_on_other_tile: bool = true

## Noise tile placement
@export var tile_noise: IslandTileNoise

@export_group("Thresholds")

## The minimum threshold
@export_range(-1, 1) var minimum: float = -1:
	set(value):
		minimum = value
		if minimum > maximum:
			maximum = minimum
		emit_changed()

## The maximum threshold
@export_range(-1, 1) var maximum: float = 1:
	set(value):
		maximum = value
		if maximum < minimum:
			minimum = maximum
		emit_changed()
