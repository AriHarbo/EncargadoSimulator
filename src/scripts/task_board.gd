extends Node3D

# Asignar en el inspector — la UI que se abre al interactuar
@export var task_board_ui: CanvasLayer


func action_use() -> void:
	if task_board_ui:
		task_board_ui.abrir()
