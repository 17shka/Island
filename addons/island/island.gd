@tool
@icon("icon.svg")
class_name Island
extends Node2D

@export var settings: IslandSettings
@export var random_seed: bool = true
@export var timeout_limit: int = 10

var seed: int = randi()
var land_layers: Array = []

func _ready() -> void:
	generate()

func generate() -> void:
	var start_time = Time.get_ticks_usec()
	var timeout_limit_us = timeout_limit * 1000000 if timeout_limit >= 0 else -1
	erase()
	apply_settings()
	create_land()
	if settings.enabled_scene:
		create_scene(start_time, timeout_limit_us)
	var total_time = Time.get_ticks_usec() - start_time
	print("Creation finished. Time: " + str(total_time / 1000000.0) + " seconds.")

func erase() -> void:

	land_layers.clear()
	for child in get_children():
		child.queue_free()
	

func apply_settings() -> void:
	if settings.modifier:
		apply_modifier()
	if random_seed:
		seed = randi()
	for noise_layer in get_valid_noise_texture():
		for noise in noise_layer.noises:
			noise.seed = seed
	if settings.enabled_scene:
		for scene_data in settings.scenes:
			if scene_data.noise and scene_data.noise.noise:
				scene_data.noise.noise.seed = seed

func apply_modifier() -> void:
	for modifier in settings.modifier:
		if modifier and not modifier.enabled:
			continue
		if modifier is IslandBorder:
			var border = preload("res://addons/island/modifiers/border/border.tscn")
			var instance = border.instantiate()
			instance.size = settings.world_size
			instance.inner_size = Vector2i(modifier.inner_size, modifier.inner_size)
			instance.color = modifier.color
			add_child(instance)

func get_valid_noise_texture() -> Array:
	var valid_noise = []
	for noise_layer in settings.noise_layers:
		if noise_layer.enabled:
			var valid_noises = []
			for noise in noise_layer.noises:
				if noise:
					valid_noises.append(noise)
			
			if valid_noises.size() > 0:
				valid_noise.append(noise_layer)
				var texture: ImageTexture = generate_noise_texture(noise_layer.size, valid_noises, noise_layer.falloff_map)
				noise_layer.texture = texture
	return valid_noise


func generate_noise_texture(size: Vector2i, noises: Array, falloff_map: GradientTexture2D) -> ImageTexture:
	var img = Image.create(size.x, size.y, false, Image.FORMAT_RGB8)
	var min_val = INF
	var max_val = -INF

	# вычисление диапазона шума
	for x in range(size.x):
		for y in range(size.y):
			var value = 0.0
			for noise in noises:
				value += noise.get_noise_2d(x, y)
			value /= noises.size()
			min_val = min(min_val, value)
			max_val = max(max_val, value)

	# генерация текстуры
	for x in range(size.x):
		for y in range(size.y):
			var value = 0.0
			for noise in noises:
				value += noise.get_noise_2d(x, y)
			value /= noises.size()
			value = (value - min_val) / (max_val - min_val) # нормализация [0,1]

			if falloff_map:
				var falloff_value = falloff_map.get_image().get_pixel(x * falloff_map.get_width() / size.x, y * falloff_map.get_height() / size.y).r
				value *= falloff_value # наложение falloff_map
			img.set_pixel(x, y, Color(value, value, value))

	var texture = ImageTexture.create_from_image(img)
	return texture

func create_land() -> void:
	for noise_layer in get_valid_noise_texture():
		var texture = noise_layer.texture
		# Получаем размер текстуры
		var texture_size = Vector2i(texture.get_width(), texture.get_height())
		var land_scale = settings.world_size / texture_size

		# Создаем ColorRect и настраиваем его
		var land = ColorRect.new()
		if noise_layer.title:
			land.name = noise_layer.title
		land.size = texture_size * land_scale
		
		# Создаем и настраиваем ShaderMaterial
		var shader_mat = ShaderMaterial.new()
		shader_mat.shader = load("res://addons/island/shader/coloring.gdshader")
		shader_mat.set_shader_parameter("noise_texture", texture)
		shader_mat.set_shader_parameter("coloring", noise_layer.coloring)
		shader_mat.set_shader_parameter("falloff_map", noise_layer.falloff_map)
		land.material = shader_mat

		# Добавляем в сцену
		add_child(land)
		land_layers.append(land)

func create_scene(start_time: int, timeout_limit_us: int) -> void:
	if not settings.enabled_scene:
		return

	var placed_positions := []
	var scene_count := settings.scenes.size()

	for i in scene_count:
		var scene = settings.scenes[i]
		if not scene.enabled or not scene.scene or scene.layer >= land_layers.size():
			continue

		var noise_layer = settings.noise_layers[scene.layer]
		var texture = noise_layer.texture
		var texture_img = texture.get_image()
		var texture_size = Vector2i(texture.get_width(), texture.get_height())
		var land_scale = settings.world_size / texture_size

		var spacing_sqr = scene.spacing.length_squared()

		for x in texture_size.x:
			for y in texture_size.y:
				if timeout_limit_us > 0 and Time.get_ticks_usec() - start_time > timeout_limit_us:
					print("Scene generation timed out.")
					return

				var pixel_value = texture_img.get_pixel(x, y).r
				if pixel_value < scene.minimum or pixel_value > scene.maximum:
					continue

				if scene.noise:
					var noise_value = scene.noise.noise.get_noise_2d(x, y)
					if noise_value < scene.noise.min or noise_value > scene.noise.max:
						continue

				var world_pos = Vector2i(x, y) * land_scale

				# проверяем расстояние до всех ранее размещенных объектов
				var can_place = true
				for placed in placed_positions:
					if world_pos.distance_squared_to(placed) < spacing_sqr:
						can_place = false
						break

				if can_place:
					var instance = scene.scene.instantiate()
					instance.position = world_pos
					instance.z_index += scene.z_index
					instance.z_as_relative = false
					#land_layers[scene.layer].add_child(instance)
					add_child(instance)
					placed_positions.append(world_pos)

					# ограничиваем список, но сохраняем больше значений
					if placed_positions.size() > 50000:
						placed_positions = placed_positions.slice(-25000, placed_positions.size())  # оставляем последние 25000
