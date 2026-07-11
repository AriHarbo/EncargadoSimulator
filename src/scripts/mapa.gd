extends Node3D

@onready var dialogo_ui: CanvasLayer = $DialogoUI


func _ready() -> void:
	# Conectar la senal del Don al dialogo
	GameManager.don_llama.connect(_on_don_llama)

	# Conectar fin de jornada (por ahora solo un print, despues sera la pantalla de resultados)
	GameManager.jornada_terminada.connect(_on_jornada_terminada)

	# Conectar tarea activada (por ahora solo print, despues actualizara el papel)
	GameManager.tarea_activada.connect(_on_tarea_activada)

	# Conectar tarea completada (por ahora solo print, despues actualizara el papel)
	GameManager.tarea_completada.connect(_on_tarea_completada)


# ---------------------------------------------------------------------------
# LLAMADA DEL DON
# ---------------------------------------------------------------------------

func _on_don_llama(llamada: BossCall) -> void:
	# Pausar el tiempo del juego mientras habla el Don
	GameManager.dia_activo = false

	dialogo_ui.mostrar_dialogo(
		"???",       # Nombre del hablante — por ahora desconocido
		llamada.lineas,
		func():
			# Al cerrar el dialogo: reanudar el tiempo y asignar las tareas
			GameManager.dia_activo = true
			GameManager.asignar_tareas(llamada.tareas_a_agregar)
	)


# ---------------------------------------------------------------------------
# TAREAS
# ---------------------------------------------------------------------------

func _on_tarea_activada(tarea: Task) -> void:
	# Por ahora solo print — cuando tengas el papel fisico, actualizar aca
	print("Tarea agregada al papel: ", tarea.nombre)


func _on_tarea_completada(tarea: Task) -> void:
	# Por ahora solo print — cuando tengas el papel fisico, actualizar aca
	print("Tarea completada: ", tarea.nombre)


# ---------------------------------------------------------------------------
# FIN DE JORNADA
# ---------------------------------------------------------------------------

func _on_jornada_terminada(resumen: Dictionary) -> void:
	print("--- FIN DE JORNADA ---")
	print("Completadas: ", resumen["completadas"], " / ", resumen["total"])
	print("Dinero ganado: $", resumen["dinero"])
	# Por ahora solo print — despues sera la pantalla de resultados
