@tool
extends EditorInspectorPlugin

func _can_handle(object: Object) -> bool:
	return object is Island 
	
func _parse_begin(object: Object) -> void:
	if object is Island:
		var button := preload("./editor_property.gd").new()
		add_custom_control(button)
