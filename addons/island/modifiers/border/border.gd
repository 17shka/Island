@tool
extends StaticBody2D

@export var size: Vector2i
@export var inner_size: int  # размер границы
@export var color: Color

@onready var polygon_2d: Polygon2D = $Polygon2D
@onready var collision_polygon_2d: CollisionPolygon2D = $CollisionPolygon2D

func _ready() -> void:
	if inner_size:
		var map_center = size / 2
		var outer_half = size / 2
		var inner_half = int((size.x - inner_size) / 2)
	  # вычисляем внутреннюю область на основе размера границы

		collision_polygon_2d.polygon = [
			# внешние точки (фиксированы)
			map_center + Vector2i(-outer_half.x, -outer_half.y),
			map_center + Vector2i(outer_half.x, -outer_half.y),
			map_center + Vector2i(outer_half.x, outer_half.y),
			map_center + Vector2i(-outer_half.x, outer_half.y),
			map_center + Vector2i(-outer_half.x, -outer_half.y),
			# внутренние точки (вычисляются на основе inner_size)
			map_center + Vector2i(-inner_half, -inner_half),
			map_center + Vector2i(-inner_half, inner_half),
			map_center + Vector2i(inner_half, inner_half),
			map_center + Vector2i(inner_half, -inner_half),
			map_center + Vector2i(-inner_half, -inner_half)
		]
		
		polygon_2d.color = color
		polygon_2d.polygon = collision_polygon_2d.polygon
