@tool
@icon("icon.svg")
class_name Island
extends Node2D

@export var tile_map_layers: Array[TileMapLayer]
@export var settings: IslandSettings
@export var random_seed: bool = true

## Creation time before timeout, value >= 0 removes it
@export var timeout_limit: int = 10

func _ready() -> void:
	generate()

func generate() -> void:
	# Начинаем отсчет времени
	var start_time = Time.get_ticks_usec()

	erase()
	apply_settings()
	create_land()
	if settings.creating_tile:
		create_tile(start_time)

	if timeout_limit >= 0:
		var elapsed_time = Time.get_ticks_usec() - start_time
		if elapsed_time > timeout_limit:
			print("Creation took too long (" + str(elapsed_time / 1000000.0) + " seconds). Operation canceled.")
			return
	
	var total_time = Time.get_ticks_usec() - start_time
	print("Creation finished. Time: " + str(total_time / 1000000.0) + " seconds.")


func erase() -> void:
	# освобождаем все дочерние узлы и очищаем слои
	for child in get_children():
		if child is Node:
			child.queue_free()
	for child in get_children():
		if child.name == "Border":
			child.queue_free()
	for layer in get_valid_tile_map_layers():
		layer.clear()

func apply_settings() -> void:
	var min_size = get_min_noise_texture_size()

	for noise_layer in get_valid_noise_texture():
		noise_layer.noise_texture.width = min_size.x
		noise_layer.noise_texture.height = min_size.y
		
		if noise_layer.falloff_map:
			noise_layer.falloff_map.width = min_size.x
			noise_layer.falloff_map.height = min_size.y
		
	# настраиваем шумовые слои
	if settings.modifier:
		apply_modifier()

	if random_seed:
		for noise_layer in get_valid_noise_texture():
			noise_layer.noise_texture.noise.seed = randi()

		if settings.creating_tile:
			for tile_data in settings.tile:
				if tile_data.tile_noise and tile_data.tile_noise.noise:
					tile_data.tile_noise.noise.seed = randi()

func get_valid_tile_map_layers() -> Array:
	var valid_tile_map_layers = []
	for layer in tile_map_layers:
		if layer != null and layer.tile_set != null:
			valid_tile_map_layers.append(layer)
	return valid_tile_map_layers

func get_valid_noise_texture() -> Array:
	var noise_texture = []
	for noise_layer in settings.noise_layers:
		if noise_layer.noise_texture and noise_layer.noise_texture.noise:
			noise_texture.append(noise_layer)
	return noise_texture

func get_min_noise_texture_size() -> Vector2i:
	var max_size = Vector2i.ZERO
	var max_tile_size = Vector2i.ZERO
	
	# Находим слой с самым большим tile_size
	for layer in get_valid_tile_map_layers():
		if layer.tile_set and layer.tile_set.tile_size.x * layer.tile_set.tile_size.y > max_tile_size.x * max_tile_size.y:
			max_tile_size = layer.tile_set.tile_size
	
	# Вычисляем размер noise_texture
	if max_tile_size != Vector2i.ZERO:
		max_size = settings.world_size / max_tile_size
	
	return max_size


func apply_modifier() -> void:
	# применяем модификаторы, например границу острова
	for modifier in settings.modifier:
		if not modifier.enabled:
			continue
		if modifier is IslandBorder:
			var border = preload("res://addons/island/modifiers/border/border.tscn")
			var instance = border.instantiate()
			instance.size = settings.world_size
			instance.inner_size = Vector2i(modifier.inner_size, modifier.inner_size)
			instance.color = modifier.color
			add_child(instance)

func create_land() -> void:
	# создаем ландшафт для каждого шумового слоя
	for noise_layer in get_valid_noise_texture():
		if not noise_layer.noise_texture:
			continue
		var tex_size = Vector2i(noise_layer.noise_texture.width, noise_layer.noise_texture.height)
		var land_scale = settings.world_size / tex_size
		var land = ColorRect.new()
		if noise_layer.title:
			land.name = noise_layer.title
		land.size = tex_size
		land.scale = land_scale
		var shader_mat = ShaderMaterial.new()
		shader_mat.shader = load("res://addons/island/shader/coloring.gdshader")
		shader_mat.set_shader_parameter("noise_texture", noise_layer.noise_texture)
		shader_mat.set_shader_parameter("coloring", noise_layer.coloring)
		shader_mat.set_shader_parameter("falloff_map", noise_layer.falloff_map)
		land.material = shader_mat
		add_child(land)

func create_tile(start_time: int) -> void:
	for tile_data in settings.tile:
		if not tile_data.enabled or not tile_data.tile_info:
			continue
		if tile_data.tile_info.tile_map_layer >= tile_map_layers.size() or tile_data.tile_info.noise_layer >= settings.noise_layers.size():
			continue
		var layer = tile_map_layers[tile_data.tile_info.tile_map_layer]
		var noise_layer = get_valid_noise_texture()[tile_data.tile_info.noise_layer]
		var scene_collection = tile_data.tile_info.collection_id
		var scene = tile_data.tile_info.scene_id
		var tile_dims = settings.world_size / layer.tile_set.tile_size
		var current_tile_size = layer.tile_set.tile_size
		var noise_texture_size = Vector2(noise_layer.noise_texture.width, noise_layer.noise_texture.height)
		var t = Vector2(tile_dims.x, tile_dims.y) / noise_texture_size
		for x in range(tile_dims.x):
			if timeout_limit >= 0 and (Time.get_ticks_usec() - start_time) > timeout_limit * 1000000:
				return
			for y in range(tile_dims.y):
				if timeout_limit >= 0 and (Time.get_ticks_usec() - start_time) > timeout_limit * 1000000:
					return
				var pos = Vector2i(x, y)
				if tile_data.prevent_on_other_tile and is_tile_occupied(pos, current_tile_size):
					continue
				var sample_x = x / t.x
				var sample_y = y / t.y
				var noise_val = noise_layer.noise_texture.noise.get_noise_2d(sample_x, sample_y)
				if noise_layer.falloff_map:
					var sample_ix = int(sample_x)
					var sample_iy = int(sample_y)
					var falloff_val = noise_layer.falloff_map.get_image().get_pixel(sample_ix, sample_iy).r
					noise_val /= falloff_val
				if noise_val < tile_data.minimum or noise_val > tile_data.maximum:
					continue
				var can_place = true
				if tile_data.tile_noise and tile_data.tile_noise.noise:
					var tile_noise_val = tile_data.tile_noise.noise.get_noise_2d(sample_x, sample_y)
					can_place = tile_noise_val >= tile_data.tile_noise.min and tile_noise_val <= tile_data.tile_noise.max
				if can_place:
					layer.set_cell(pos, scene_collection, Vector2i(0, 0), scene)

func is_tile_occupied(pos: Vector2i, current_size: Vector2i) -> bool:
	# проверяем занятость позиции в других слоях
	for layer in get_valid_tile_map_layers():
		if not layer.tile_set:
			continue
		var adjusted = Vector2i(
			(pos.x * current_size.x) / layer.tile_set.tile_size.x,
			(pos.y * current_size.y) / layer.tile_set.tile_size.y
		)
		if layer.get_cell_source_id(adjusted) != -1:
			return true
	return false
