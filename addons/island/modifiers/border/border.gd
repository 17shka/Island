@tool
extends StaticBody2D

@export var size: Vector2i
@export var inner_size: Vector2i
@export var color: Color

@onready var polygon_2d: Polygon2D = $Polygon2D
@onready var collision_polygon_2d: CollisionPolygon2D = $CollisionPolygon2D

func _ready() -> void:  
	create()

func create() -> void:
	var rect = [  
		Vector2i(0, 0), 
		Vector2i(size.x, 0),  
		Vector2i(size),  
		Vector2i(0, size.y),
		Vector2i(0, 0),

		Vector2i(inner_size),  
		Vector2i(inner_size.x, size.y - inner_size.y),  
		Vector2i(size - inner_size),  
		Vector2i(size.x - inner_size.x, inner_size.y),
		Vector2i(inner_size)
	]

	collision_polygon_2d.polygon = rect  
	polygon_2d.polygon = rect  
	polygon_2d.color = color
