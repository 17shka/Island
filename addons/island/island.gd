@tool
@icon("icon.svg")
class_name Island
extends Node2D

@export var tile_map_layers: Array[TileMapLayer]

@export var settings: IslandSettings
@export var random_seed: bool = true:
	set(value):
		random_seed = value
		notify_property_list_changed()

## correction of texture size to avoid inaccuracies (Don't touch it if you don't know what you're doing)
@export var correction: bool = true

## Simulates scrolling (useful if you want to make a planet) (very poorly optimized with the “creating tile” setting)
@export var scrolling: bool
func _ready() -> void:
	generate()

func generate() -> void:
	erase()
	set_settings()
	create_land()
	if settings.creating_tile:
		create_tile()

func erase() -> void:
	for child in get_children():
		if child is Node:
			child.queue_free()

	for tile_map_layer in tile_map_layers:
		tile_map_layer.clear() 

	for child in get_children():
		if child.name == "Border":
			child.queue_free()

func set_settings() -> void:
	for i in settings.noise_layers:
		if i.noise_texture:
			if i.noise_texture.noise:
				if random_seed:
					i.noise_texture.noise.seed = randi()
					if settings.creating_tile:
						for tile_data in settings.tile:
							if tile_data.tile_noise:
								if tile_data.tile_noise.noise:
									tile_data.tile_noise.noise.seed = randi()
				if correction:
					for tile_map_layer in tile_map_layers:
						if tile_map_layer.tile_set:
							var correction_value = settings.world_size / tile_map_layer.tile_set.tile_size

							i.noise_texture.width = correction_value.x
							i.noise_texture.height = correction_value.y
							
							if i.falloff_map:
								i.falloff_map.width = correction_value.x
								i.falloff_map.height = correction_value.y

	if settings.modifier:
		modifier_application()

	if scrolling:
		random_seed = false

		var timer = Timer.new()
		timer.name = "ScrollingOffset"
		timer.wait_time = 0.001
		timer.autostart = true
		timer.timeout.connect(scrolling_offset)
		add_child(timer)

func create_land() -> void:
	for i in settings.noise_layers:
		
		if i.noise_texture:
			var noise_texture_size = Vector2i(i.noise_texture.width, i.noise_texture.height)
			var land_scale = settings.world_size / noise_texture_size
			var land = ColorRect.new()
			var shader_material = ShaderMaterial.new()

			land.name = i.title
			land.size = noise_texture_size
			land.scale = land_scale

			shader_material.shader = load("res://addons/island/shader/coloring.gdshader")

			# Передаем параметры текстуры в шейдер
			shader_material.set_shader_parameter("noise_texture", i.noise_texture)
			shader_material.set_shader_parameter("coloring", i.coloring)
			shader_material.set_shader_parameter("falloff_map", i.falloff_map)

			land.material = shader_material
			add_child(land)
	
func create_tile() -> void:
	for tile_data in settings.tile:
		if tile_data.tile_info:
			if tile_data.tile_info.tile_map_layer < tile_map_layers.size() and tile_data.tile_info.noise_layer < settings.noise_layers.size():

				var tile_map_layer = tile_map_layers[tile_data.tile_info.tile_map_layer]
				var noise_layer = tile_data.tile_info.noise_layer

				var scene_collection = tile_data.tile_info.collection_id
				var scene = tile_data.tile_info.scene_id

				var tile_dimensions = settings.world_size / tile_map_layer.tile_set.tile_size
				var current_tile_size = tile_map_layer.tile_set.tile_size

				# Пройдем по всем тайлам и разместим соответствующий тайл в зависимости от шума
				for x in range(tile_dimensions.x):
					for y in range(tile_dimensions.y):
						var tile_position = Vector2i(x, y)

						# Проверяем наличие других плиток, если prevent_on_other_tile включен
						if tile_data.prevent_on_other_tile:
							var occupied = false
							for layer in tile_map_layers:
								if layer.tile_set:
									var layer_tile_size = layer.tile_set.tile_size
									
									# Переводим координаты в другой слой с учетом размера тайлов
									var adjusted_position = Vector2i(
										(tile_position.x * current_tile_size.x) / layer_tile_size.x,
										(tile_position.y * current_tile_size.y) / layer_tile_size.y
									)

									if layer.get_cell_source_id(adjusted_position) != -1:
										occupied = true
										break
								if occupied:
									continue

						# Получаем шум для текущей позиции
						if settings.noise_layers[noise_layer].noise_texture.noise:
							var noise_value = settings.noise_layers[noise_layer].noise_texture.noise.get_noise_2d(x, y)
							# получаем falloff_map
							if settings.noise_layers[noise_layer].falloff_map:
								var falloff_map = settings.noise_layers[noise_layer].falloff_map 
								var falloff_image = settings.noise_layers[noise_layer].falloff_map.get_image()
								var falloff_value = falloff_image.get_pixel(x, y).r
								noise_value /= falloff_value

							# Проверяем, попадает ли значение шума в первый допустимый диапазон
							if noise_value >= tile_data.minimum and noise_value <= tile_data.maximum:
								var can_place = true  # Флаг, можно ли размещать плитку

								# Если tile_noise задан, проверяем его
								if tile_data.tile_noise and tile_data.tile_noise.noise:
									var tile_noise_value = tile_data.tile_noise.noise.get_noise_2d(x, y)
									can_place = tile_noise_value >= tile_data.tile_noise.min and tile_noise_value <= tile_data.tile_noise.max

								# Если проверка прошла, устанавливаем тайл
								if can_place:
									tile_map_layer.set_cell(tile_position, scene_collection, Vector2i(0, 0), scene)

func modifier_application() -> void:
	for modifier in settings.modifier:
		if modifier.enabled:
			if modifier is IslandBorder:
				var border = preload("res://addons/island/modifiers/border/border.tscn")
				var instance = border.instantiate()
				instance.size = settings.world_size
				instance.inner_size = modifier.inner_size
				instance.color = modifier.color
				add_child(instance)


func scrolling_offset() -> void:
	for noise_layer in settings.noise_layers:
		noise_layer.noise_texture.noise.offset.x += 0.01
		noise_layer.noise_texture.noise.offset.y += 0.01
	
	if settings.creating_tile:
		for tile in settings.tile:
			if tile.tile_noise.noise:
				tile.tile_noise.noise.offset.x +=0.01
				tile.tile_noise.noise.offset.y +=0.01

		for tile_map_layer in tile_map_layers:
			tile_map_layer.clear()
		create_tile()
