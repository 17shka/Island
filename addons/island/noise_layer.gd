@tool
extends Resource
class_name IslandNoiseLayer

@export var enabled: bool = true

@export var title: String = "":
	set(value):
		title = value
		resource_name = title

@export var size: Vector2i = Vector2i(64, 64)

@export var texture: Texture2D

@export var noises: Array[FastNoiseLite]:
	set(value):
		if value.size() > 0:
			value[-1] = value[-1] if value[-1] is FastNoiseLite else FastNoiseLite.new()
		noises = value

## What colors the noise will be colored in
@export var coloring: GradientTexture1D = create_gradient_texture():
	set(value):
		coloring = value if value is GradientTexture1D else create_gradient_texture()

static func create_gradient_texture() -> GradientTexture1D:
	var gradient = Gradient.new()
	var texture = GradientTexture1D.new()
	texture.gradient = gradient
	return texture


## Doesn't work for creating tiles
@export var falloff_map: GradientTexture2D
