
extends Node3D
 
@onready var dialogo_ui: CanvasLayer = $DialogoUI
@onready var incoming_call: CanvasLayer = $IncomingCall
 
 
func _ready() -> void:
	# Pasar la referencia del DialogoUI al IncomingCall
	incoming_call.dialogo_ui = dialogo_ui
 
	# Conectar senales del GameManager
	GameManager.don_llama.connect(_on_don_llama)
	GameManager.jornada_terminada.connect(_on_jornada_terminada)
	GameManager.tarea_activada.connect(_on_tarea_activada)
	GameManager.tarea_completada.connect(_on_tarea_completada)
 
	# Esperar 5 segundos antes de iniciar el dia
	await get_tree().create_timer(5.0).timeout
	GameManager.iniciar_dia()
 
 
# ---------------------------------------------------------------------------
# LLAMADA DEL DON
# ---------------------------------------------------------------------------
 
func _on_don_llama(llamada: BossCall) -> void:
	# Pausar el tiempo mientras suena el telefono
	GameManager.dia_activo = false
	incoming_call.sonar(llamada)
 
 
# ---------------------------------------------------------------------------
# TAREAS
# ---------------------------------------------------------------------------
 
func _on_tarea_activada(tarea: Task) -> void:
	print("Tarea agregada al papel: ", tarea.nombre)
 
 
func _on_tarea_completada(tarea: Task) -> void:
	print("Tarea completada: ", tarea.nombre)
 
 
# ---------------------------------------------------------------------------
# FIN DE JORNADA
# ---------------------------------------------------------------------------
 
func _on_jornada_terminada(resumen: Dictionary) -> void:
	print("--- FIN DE JORNADA ---")
	print("Completadas: ", resumen["completadas"], " / ", resumen["total"])
	print("Dinero ganado: $", resumen["dinero"])
