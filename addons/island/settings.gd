@tool
class_name IslandSettings
extends Resource

@export var world_size: Vector2i = Vector2i(2048, 2048)
@export var noise_layers: Array[IslandNoiseLayer]:
	set(value):
		if value.size() > 0:
			value[-1] = value[-1] if value[-1] is IslandNoiseLayer else IslandNoiseLayer.new()
		noise_layers = value

@export_group("Region")
@export var enabled_region: bool
@export var region: Array[IslandRegion]:
	set(value):
		if value.size() > 0:
			value[-1] = value[-1] if value[-1] is IslandRegion else IslandRegion.new()
		region = value

@export_group("Scene")
@export var enabled_scene: bool
@export var scenes: Array[IslandSceneData]:
	set(value):
		if value.size() > 0:
			value[-1] = value[-1] if value[-1] is IslandSceneData else IslandSceneData.new()
		scenes = value

@export_category("Modifier")
@export var modifier: Array[IslandModifier]
