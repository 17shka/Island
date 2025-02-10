extends CanvasLayer

var island: Island

func _ready() -> void:
	if get_parent().has_node("Island"):
		island = get_parent().get_node("Island")
		visible = true

func _on_generate_pressed() -> void:
	island.generate()


func _on_clear_pressed() -> void:
	island.erase()
