@tool
class_name IslandSettings
extends Resource

@export var world_size: Vector2i = Vector2i(1024, 1024)
@export var noise_layers: Array[CombinedNoiseTexture]:
	set(value):
		if value.size() > 0:
			value[-1] = value[-1] if value[-1] is CombinedNoiseTexture else CombinedNoiseTexture.new()
		noise_layers = value

@export_group("Tile")
@export var creating_tile: bool

@export var tile: Array[IslandTileData]:
	set(value):
		if value.size() > 0:
			value[-1] = value[-1] if value[-1] is IslandTileData else IslandTileData.new()
		tile = value

@export_category("Modifier")
@export var modifier: Array[IslandModifier]
