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
	if inner_size:  
		var outer_rect = [  
			Vector2(0, 0),  
			Vector2(size.x, 0),  
			Vector2(size.x, size.y),  
			Vector2(0, size.y)  
		]  

		var inner_rect = [  
			Vector2(inner_size.x, inner_size.y),  
			Vector2(inner_size.x, size.y - inner_size.y),  
			Vector2(size.x - inner_size.x, size.y - inner_size.y),  
			Vector2(size.x - inner_size.x, inner_size.y)  
		]  

		var final_polygon = outer_rect + inner_rect  
		collision_polygon_2d.polygon = final_polygon  
		polygon_2d.polygon = final_polygon  
		polygon_2d.color = color  
