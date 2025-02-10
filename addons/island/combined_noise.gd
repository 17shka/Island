@tool
extends Resource
class_name CombinedNoiseTexture

@export var title: String = "":
	set(value):
		title = value
		resource_name = title

@export var noise_texture: NoiseTexture2D

## What colors the noise will be colored in
@export var coloring: GradientTexture1D

## Doesn't work for creating tiles
@export var falloff_map: GradientTexture2D
