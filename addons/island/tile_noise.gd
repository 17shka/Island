@tool
class_name IslandTileNoise
extends Resource

@export var noise: Noise

@export_group("Thresholds")

## The minimum threshold
@export_range(-1, 1) var min: float = 1:
	set(value):
		min = value
		if min > max:
			max = min
		emit_changed()

## The maximum threshold
@export_range(-1, 1) var max: float = 1:
	set(value):
		max = value
		if max < min:
			min = max
		emit_changed()
