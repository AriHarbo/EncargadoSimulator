extends Node
 
# ---------------------------------------------------------------------------
# SENALES
# ---------------------------------------------------------------------------
 
signal hora_cambiada(hora: float)
signal fase_cambiada(fase: String)
signal tarea_activada(tarea: Task)
signal tarea_completada(tarea: Task)
signal tarea_fallada(tarea: Task)
signal jornada_terminada(resumen: Dictionary)
signal don_llama(llamada: BossCall)
 
 
# ---------------------------------------------------------------------------
# TIEMPO
# ---------------------------------------------------------------------------
 
const HORA_INICIO: float = 8.0
const HORA_FIN: float = 30.0  # 6:00am del dia siguiente
 
@export var segundos_por_hora: float = 60.0
 
var hora_actual: float = HORA_INICIO
var fase_actual: String = "manana"
var dia_activo: bool = false
 
 
# ---------------------------------------------------------------------------
# TAREAS
# _pool_tareas: todas las tareas del dia, para busqueda rapida por id
# tareas_asignadas: solo las que el Don ya asigno (las que aparecen en el papel)
# _tareas_activas: tareas asignadas que todavia no se completaron ni fallaron
# ---------------------------------------------------------------------------
 
var _pool_tareas: Dictionary = {}
var tareas_asignadas: Array[Task] = []
var _tareas_activas: Array[Task] = []
var _tareas_completadas: Array[Task] = []
var _tareas_falladas: Array[Task] = []
 
 
# ---------------------------------------------------------------------------
# LLAMADAS DEL DON
# ---------------------------------------------------------------------------
 
var llamadas_del_don: Array[BossCall] = []
 
 
# ---------------------------------------------------------------------------
# ECONOMIA
# ---------------------------------------------------------------------------
 
var dinero_ganado: int = 0
 
 
# ---------------------------------------------------------------------------
# INICIALIZACION
# ---------------------------------------------------------------------------
 
func _ready() -> void:
	_cargar_recursos()
	await get_tree().process_frame
	print("Hora actual: ", hora_como_string())
	print("Tareas cargadas en pool: ", _pool_tareas.size())
	for id in _pool_tareas:
		print("  - ", id, " | ", _pool_tareas[id].nombre)
 
 
func _cargar_recursos() -> void:
	# Tareas
	var tareas_raw: Array[Task] = [
		load("res://src/resources/tareas/dia_01/tarea_01_presentaciones.tres"),
		load("res://src/resources/tareas/dia_01/tarea_02_cuarto_conserje.tres"),
		load("res://src/resources/tareas/dia_01/tarea_03_habitacion_1.tres"),
		load("res://src/resources/tareas/dia_01/tarea_04_habitacion_2.tres"),
		load("res://src/resources/tareas/dia_01/tarea_05_foco.tres"),
		load("res://src/resources/tareas/dia_01/tarea_06_cadaver.tres"),
	]
 
	# Llamadas del Don
	llamadas_del_don = [
		load("res://src/resources/llamadas/dia_01/boss_call_01_bienvenida.tres"),
		load("res://src/resources/llamadas/dia_01/boss_call_02_cuarto.tres"),
		load("res://src/resources/llamadas/dia_01/boss_call_04_foco.tres"),
		load("res://src/resources/llamadas/dia_01/boss_call_05_cadaver.tres"),
	]
 
	# Construir el pool de tareas para busqueda rapida por id
	_pool_tareas.clear()
	for tarea in tareas_raw:
		if tarea == null:
			push_error("GameManager: una tarea no se pudo cargar. Verificar rutas.")
			continue
		_pool_tareas[tarea.id] = tarea
 
 
func iniciar_dia() -> void:
	hora_actual = HORA_INICIO
	fase_actual = "manana"
	dia_activo = true
	dinero_ganado = 0
 
	_tareas_activas.clear()
	_tareas_completadas.clear()
	_tareas_falladas.clear()
	tareas_asignadas.clear()
 
	# Resetear estado de todas las tareas del pool
	for id in _pool_tareas:
		_pool_tareas[id].estado = Task.Estado.PENDIENTE
 
	# Resetear llamadas
	for llamada in llamadas_del_don:
		if llamada == null:
			push_error("GameManager: una BossCall no se pudo cargar. Verificar rutas.")
			continue
		llamada.ya_se_activo = false
 
 
# ---------------------------------------------------------------------------
# LOOP PRINCIPAL
# ---------------------------------------------------------------------------
 
func _process(delta: float) -> void:
	if not dia_activo:
		return
 
	_avanzar_tiempo(delta)
	_revisar_activaciones()
	_revisar_limites()
 
	if hora_actual >= HORA_FIN:
		_terminar_dia()
 
 
func _avanzar_tiempo(delta: float) -> void:
	var hora_anterior: float = hora_actual
	hora_actual += delta / segundos_por_hora
 
	if int(hora_actual * 60) != int(hora_anterior * 60):
		emit_signal("hora_cambiada", hora_actual)
 
	var fase_nueva: String = _calcular_fase()
	if fase_nueva != fase_actual:
		fase_actual = fase_nueva
		emit_signal("fase_cambiada", fase_actual)
 
 
func _calcular_fase() -> String:
	if hora_actual < 13.0:
		return "manana"
	elif hora_actual < 20.0:
		return "tarde"
	else:
		return "noche"
 
 
# ---------------------------------------------------------------------------
# LOGICA DE LLAMADAS Y TAREAS
# ---------------------------------------------------------------------------
 
func _revisar_activaciones() -> void:
	for llamada in llamadas_del_don:
		if llamada == null or llamada.ya_se_activo:
			continue
 
		var debe_activarse: bool = false
 
		match llamada.tipo_activacion:
			BossCall.TipoActivacion.POR_TIEMPO:
				debe_activarse = hora_actual >= llamada.hora_activacion
 
			BossCall.TipoActivacion.POR_TAREA:
				for tarea in _tareas_completadas:
					if tarea.id == llamada.tarea_activadora:
						debe_activarse = true
						break
 
		if debe_activarse:
			llamada.ya_se_activo = true
			emit_signal("don_llama", llamada)
 
 
func _revisar_limites() -> void:
	for tarea in _tareas_activas.duplicate():
		if tarea.tiene_limite and hora_actual >= tarea.hora_limite:
			if tarea.estado == Task.Estado.ACTIVA:
				_fallar_tarea(tarea)
 
 
# ---------------------------------------------------------------------------
# ACCIONES PUBLICAS
# ---------------------------------------------------------------------------
 
# Llamado desde la escena al terminar el dialogo del Don.
# Agrega las tareas indicadas al papel del jugador.
func asignar_tareas(ids: Array[String]) -> void:
	for id in ids:
		if _pool_tareas.has(id):
			var tarea: Task = _pool_tareas[id]
			if tarea.estado == Task.Estado.PENDIENTE:
				tarea.estado = Task.Estado.ACTIVA
				tareas_asignadas.append(tarea)
				_tareas_activas.append(tarea)
				emit_signal("tarea_activada", tarea)
		else:
			push_warning("GameManager.asignar_tareas: no existe tarea con id '%s'" % id)
 
 
# Llamado desde los scripts de cada mecanica cuando el jugador completa algo.
# Ejemplo: GameManager.completar_tarea("limpiar_hab1")
func completar_tarea(id: String) -> void:
	var tarea: Task = _buscar_tarea_activa(id)
	if tarea == null:
		push_warning("GameManager: se intento completar la tarea '%s' pero no esta activa." % id)
		return
 
	tarea.estado = Task.Estado.COMPLETADA
	_tareas_activas.erase(tarea)
	_tareas_completadas.append(tarea)
	dinero_ganado += tarea.dinero
	emit_signal("tarea_completada", tarea)
 
 
func _fallar_tarea(tarea: Task) -> void:
	tarea.estado = Task.Estado.FALLADA
	_tareas_activas.erase(tarea)
	_tareas_falladas.append(tarea)
	emit_signal("tarea_fallada", tarea)
 
 
func _buscar_tarea_activa(id: String) -> Task:
	for tarea in _tareas_activas:
		if tarea.id == id:
			return tarea
	return null
 
 
# ---------------------------------------------------------------------------
# FIN DE JORNADA
# ---------------------------------------------------------------------------
 
func _terminar_dia() -> void:
	dia_activo = false
 
	var resumen: Dictionary = {
		"completadas": _tareas_completadas.size(),
		"falladas": _tareas_falladas.size(),
		"total": _pool_tareas.size(),
		"dinero": dinero_ganado,
		"tareas_completadas": _tareas_completadas,
		"tareas_falladas": _tareas_falladas
	}
 
	emit_signal("jornada_terminada", resumen)
 
 
# ---------------------------------------------------------------------------
# UTILIDADES
# ---------------------------------------------------------------------------
 
# Devuelve la hora como string legible: 8.5 -> "08:30"
func hora_como_string() -> String:
	var horas: int = int(hora_actual) % 24
	var minutos: int = int((hora_actual - int(hora_actual)) * 60)
	return "%02d:%02d" % [horas, minutos]
 
 
# Para la UI del papel: devuelve solo las tareas que el Don ya asigno
func get_tareas_asignadas() -> Array[Task]:
	return tareas_asignadas
 
 
# Para debug: devuelve todas las tareas del pool
func get_todas_las_tareas() -> Array[Task]:
	var resultado: Array[Task] = []
	for id in _pool_tareas:
		resultado.append(_pool_tareas[id])
	return resultado
