extends Camera2D

@export var camera_movent = 720
@export var zoming = 0.1

@export var limit_camera: bool

func  _ready() -> void:
	zoming = zoming + 1
	if get_parent().has_node("Island"):
		var island =  get_parent().get_node("Island")
		position = island.settings.world_size / 2
	
		if limit_camera:
			set_limit(SIDE_LEFT, 0)
			set_limit(SIDE_TOP, 0)
			set_limit(SIDE_RIGHT, island.settings.world_size.x)
			set_limit(SIDE_BOTTOM, island.settings.world_size.y)
			
	
	visible = true

func _process(delta):
	var direction = Vector2.ZERO

	if Input.is_action_pressed("ui_right"):
		direction.x += 1
	if Input.is_action_pressed("ui_left"):
		direction.x -= 1
	if Input.is_action_pressed("ui_down"):
		direction.y += 1
	if Input.is_action_pressed("ui_up"):
		direction.y -= 1

	var scale_factor = 1 / zoom.x
	global_position += direction.normalized() * camera_movent * scale_factor * delta

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
			zoom *= zoming
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
			zoom /= zoming

	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_MIDDLE and event.pressed:
		zoom = Vector2i(1, 1)
