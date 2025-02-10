@tool
extends EditorPlugin

var _inspector_plugin

func _enter_tree() -> void:
	# Создаём и добавляем плагин инспектора
	_inspector_plugin = preload("editor/inspector_plugin.gd").new()
	add_inspector_plugin(_inspector_plugin)

func _exit_tree() -> void:
	remove_inspector_plugin(_inspector_plugin)
