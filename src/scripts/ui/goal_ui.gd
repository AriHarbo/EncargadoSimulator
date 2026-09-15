# goal_ui.gd
extends CanvasLayer

# UI del objetivo actual: muestra un único objetivo al medio-izquierda de la
# pantalla. Se actualiza solo cuando el GameManager cambia el objetivo
# (llamadas del Don) o cuando el jugador clickea una tarea en el taskboard
# (GameManager.set_objetivo). Es meramente visual: no bloquea nada.

@onready var panel: Panel = $Panel
@onready var objetivo_label: Label = $Panel/VBoxContainer/ObjetivoLabel

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	GameManager.objetivo_cambiado.connect(_on_objetivo_cambiado)
	_actualizar(GameManager.objetivo_actual)

func _on_objetivo_cambiado(texto: String) -> void:
	_actualizar(texto)

func _actualizar(texto: String) -> void:
	if texto == "":
		panel.hide()
		return
	objetivo_label.text = texto
	panel.show()
