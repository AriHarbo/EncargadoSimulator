extends Area3D

# ---------------------------------------------------------------------------
# AREA DE LIMPIEZA DE HABITACION
# Genera de forma aleatoria el "desorden" de una habitacion (toallas sucias,
# manchas, basura y opcionalmente sangre) repartido por el piso. Mientras el
# jugador limpia, va mostrando en la UI de objetivo el progreso de cada
# subtarea. Cuando esta todo listo, completa la task de la habitacion.
#
# Uso:
#   1. Agregar un Area3D que cubra toda la habitacion (o su piso) con un
#      CollisionShape3D tipo BoxShape3D. Los items spawnean como hijos del
#      Area3D dentro de los limites de esa caja.
#   2. Configurar: tarea_id, medidor_toallas (NodePath al TowelCabinet de la
#      habitacion) e incluir_sangre (solo habitacion 2).
# ---------------------------------------------------------------------------

const DIRTINESS_SCENE := preload("res://src/scenes/cleanables/dirtiness.tscn")
const BLOOD_STAIN_SCENE := preload("res://src/scenes/cleanables/blood_stain.tscn")
const TRASH_ITEM_SCENE := preload("res://src/scenes/props/trash_item.tscn")
const DIRTY_TOWEL_SCENE := preload("res://src/scenes/props/dirty_towel.tscn")

# Alturas de apoyo en el piso para los elementos "pegados" al suelo
const ALTURA_SUCIEDAD := 0.05
const ALTURA_SANGRE := 0.02

# -- Configuracion de la habitacion --
@export var tarea_id: String = "limpiar_hab1"
@export var incluir_sangre: bool = false
@export var medidor_toallas: NodePath   # TowelCabinet de la habitacion

# -- Cantidades aleatorias (min-max inclusive) --
@export_group("Cantidades (min-max aleatorios)")
@export var min_toallas: int = 1
@export var max_toallas: int = 2
@export var min_manchas: int = 3
@export var max_manchas: int = 6
@export var min_basura: int = 4
@export var max_basura: int = 10
@export var min_sangre: int = 1
@export var max_sangre: int = 3

@export_group("Spawn")
@export var margen_borde: float = 0.8
@export var altura_caida_items: float = 0.5   # toallas y basura, caen al piso


# -- Estado interno --
var _jugador_dentro: bool = false
var _completado: bool = false

var _totales: Dictionary = { "manchas": 0, "basura": 0, "sangre": 0 }
var _pendientes: Dictionary = { "manchas": 0, "basura": 0, "sangre": 0 }
var _toallas_puestas: int = 0
var _toallas_target: int = 0

var _towel_cabinet = null


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

	GameManager.tarea_activada.connect(_on_tarea_activada)
	GameManager.tarea_completada.connect(_on_tarea_completada)

	_towel_cabinet = _resolver_towel_cabinet()

	_spawn_desorden()

	if _towel_cabinet:
		_toallas_puestas = _get_toallas_almacenadas()
		_towel_cabinet.toalla_guardada.connect(_on_toallas_cambiaron)
		_towel_cabinet.toalla_sacada.connect(_on_toallas_cambiaron)
	else:
		push_warning("AreaLimpieza[%s]: falta asignar 'medidor_toallas' al towel_cabinet de la habitacion." % tarea_id)


# Resuelve el nodo del TowelCabinet que tiene el script (el que posee
# stored_quantity y las señales). El NodePath puede apuntar a la raiz
# "TowelCabinet" (Node3D) o directo a su hijo "InteractArea" (StaticBody3D).
func _resolver_towel_cabinet() -> Node:
	if medidor_toallas == null or medidor_toallas.is_empty():
		return null
	var nodo = get_node_or_null(medidor_toallas)
	if nodo == null:
		return null
	if nodo.get("stored_quantity") != null:
		return nodo
	for child in nodo.get_children():
		if child.get("stored_quantity") != null:
			return child
	return null


# ---------------------------------------------------------------------------
# SPAWN ALEATORIO
# ---------------------------------------------------------------------------

func _spawn_desorden() -> void:
	var piso := _piso_local()
	_spawn_categoria(DIRTINESS_SCENE, "manchas", piso + ALTURA_SUCIEDAD, randi_range(min_manchas, max_manchas))
	_spawn_categoria(TRASH_ITEM_SCENE, "basura", piso + altura_caida_items, randi_range(min_basura, max_basura))
	if incluir_sangre:
		_spawn_categoria(BLOOD_STAIN_SCENE, "sangre", piso + ALTURA_SANGRE, randi_range(min_sangre, max_sangre))

	var cant_toallas: int = randi_range(min_toallas, max_toallas)
	_toallas_target = cant_toallas
	for i in cant_toallas:
		var toalla = DIRTY_TOWEL_SCENE.instantiate()
		toalla.position = _pos_aleatoria(piso + altura_caida_items)
		add_child(toalla)


func _spawn_categoria(scene: PackedScene, categoria: String, y: float, cantidad: int) -> void:
	_totales[categoria] = cantidad
	_pendientes[categoria] = cantidad
	for i in cantidad:
		var nodo = scene.instantiate()
		nodo.position = _pos_aleatoria(y)
		add_child(nodo)

		# El nodo que "se limpia" no siempre es la raiz: la sangre se elimina via
		# su Area3D (grupo "BloodStain"), no la raiz StaticBody3D.
		var victima: Node = nodo
		if categoria == "sangre":
			var sangre_children := _buscar_hijo_en_grupo(nodo, "BloodStain")
			if sangre_children:
				victima = sangre_children
		victima.tree_exiting.connect(_on_item_limpiado.bind(categoria))


func _buscar_hijo_en_grupo(nodo: Node, grupo: String) -> Node:
	for child in nodo.get_children():
		if child.is_in_group(grupo):
			return child
	return null


# Posicion aleatoria dentro de la caja del Area3D (coordenadas locales)
func _pos_aleatoria(y: float) -> Vector3:
	var extent := _extent_area()
	return Vector3(randf_range(-extent.x, extent.x), y, randf_range(-extent.y, extent.y))


# Devuelve la Y local del fondo de la caja del Area3D (el piso de la
# habitacion). La caja suele estar centrada en vertical (ej. y=1.5 con alto 3),
# asi que el piso no es la Y 0 local sino el borde inferior de la caja.
func _piso_local() -> float:
	for child in get_children():
		if child is CollisionShape3D and child.shape is BoxShape3D:
			return -child.shape.size.y * 0.5
	# Fallback: asumir que el piso del mundo esta en y=0
	return -global_position.y


# Devuelve las semi-dimensiones (x, z) utilizables usando el primer
# BoxShape3D de la caja, descontando el margen de borde.
func _extent_area() -> Vector2:
	for child in get_children():
		if child is CollisionShape3D and child.shape is BoxShape3D:
			var size: Vector3 = child.shape.size
			return Vector2(
				maxf(size.x * 0.5 - margen_borde, 0.2),
				maxf(size.z * 0.5 - margen_borde, 0.2)
			)
	return Vector2(3.0, 3.0)


# ---------------------------------------------------------------------------
# DETECCION DE ENTRADA / SALIDA DEL JUGADOR
# ---------------------------------------------------------------------------

func _on_body_entered(body: Node3D) -> void:
	if not body.is_in_group("player"):
		return
	_jugador_dentro = true
	if GameManager.esta_tarea_activa(tarea_id):
		_rendir_subobjetivos()
		_chequear_completado()


func _on_body_exited(body: Node3D) -> void:
	if not body.is_in_group("player"):
		return
	_jugador_dentro = false
	_ocultar_subobjetivos()


func _on_tarea_activada(tarea: Task) -> void:
	if tarea.id != tarea_id:
		return
	# Si la tarea se activa mientras el jugador esta adentro (o limpió todo
	# antes de que la asignen), mostrar el estado y verificar cierre.
	if _jugador_dentro:
		_rendir_subobjetivos()
	_chequear_completado()


func _on_tarea_completada(tarea: Task) -> void:
	if tarea.id != tarea_id:
		return
	_completado = true
	_ocultar_subobjetivos()


# ---------------------------------------------------------------------------
# PROGRESO DE LAS SUBTAREAS
# ---------------------------------------------------------------------------

func _on_item_limpiado(categoria: String) -> void:
	if _completado or not is_inside_tree():
		return
	if _pendientes.has(categoria):
		_pendientes[categoria] = maxi(_pendientes[categoria] - 1, 0)
	_rendir_subobjetivos()
	_chequear_completado()


func _on_toallas_cambiaron() -> void:
	if _completado:
		return
	_toallas_puestas = _get_toallas_almacenadas()
	_rendir_subobjetivos()
	_chequear_completado()


func _get_toallas_almacenadas() -> int:
	if _towel_cabinet == null:
		return _toallas_target
	return _towel_cabinet.stored_quantity


func _chequear_completado() -> void:
	if _completado:
		return
	if not GameManager.esta_tarea_activa(tarea_id):
		return

	var todo_listo: bool = true
	for categoria in _pendientes:
		if _pendientes[categoria] > 0:
			todo_listo = false
			break
	if _toallas_puestas < _toallas_target:
		todo_listo = false

	if todo_listo:
		_completado = true
		_ocultar_subobjetivos()
		GameManager.completar_tarea(tarea_id)


# ---------------------------------------------------------------------------
# UI DE OBJETIVO
# ---------------------------------------------------------------------------

func _rendir_subobjetivos() -> void:
	var ui = _get_objetivo_ui()
	if ui == null:
		return

	var items: Array[String] = [
		"Poner toallas limpias  %d/%d" % [_toallas_puestas, _toallas_target],
		"Limpiar manchas  %d/%d" % [_totales["manchas"] - _pendientes["manchas"], _totales["manchas"]],
		"Juntar basura  %d/%d" % [_totales["basura"] - _pendientes["basura"], _totales["basura"]],
	]
	if incluir_sangre:
		items.append("Limpiar sangre  %d/%d" % [_totales["sangre"] - _pendientes["sangre"], _totales["sangre"]])

	ui.mostrar_subobjetivos(_titulo_tarea(), items)


func _titulo_tarea() -> String:
	for tarea in GameManager.get_todas_las_tareas():
		if tarea.id == tarea_id:
			return tarea.nombre
	return tarea_id


func _ocultar_subobjetivos() -> void:
	var ui = _get_objetivo_ui()
	if ui:
		ui.ocultar_subobjetivos()


func _get_objetivo_ui():
	return get_tree().get_first_node_in_group("goal_ui")
