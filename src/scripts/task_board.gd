extends Node3D

# Asignar en el inspector — la UI que se abre al interactuar
@export var task_board_ui: CanvasLayer


func action_use() -> void:
	print("se uso el taskboard1")
	if task_board_ui:
		print("se uso el taskboard")
		task_board_ui.abrir()
