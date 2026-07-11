extends CanvasLayer

@export var panel: Panel
@export var lista_tareas: VBoxContainer
@export var hint_cerrar: Label

# Escena de un item de tarea — la creamos por código así que no necesita escena separada
var _abierto: bool = false


func _ready() -> void:
	print("panel: ", panel)
	print("lista_tareas: ", lista_tareas)
	print("hint_cerrar: ", hint_cerrar)
	panel.hide()

	# Escuchar cuando el Jefe asigna tareas nuevas para actualizar el papel
	GameManager.tarea_activada.connect(_on_tarea_activada)
	GameManager.tarea_completada.connect(_on_tarea_completada)


func _input(event: InputEvent) -> void:
	if not _abierto:
		return
	if event.is_action_just_pressed("interact") or event.is_action_just_pressed("ui_cancel"):
		cerrar()


# ---------------------------------------------------------------------------
# API PUBLICA
# ---------------------------------------------------------------------------

func abrir() -> void:
	_abierto = true
	_refrescar_lista()
	panel.show()
	get_tree().paused = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func cerrar() -> void:
	_abierto = false
	panel.hide()
	get_tree().paused = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


# ---------------------------------------------------------------------------
# LOGICA INTERNA
# ---------------------------------------------------------------------------

func _refrescar_lista() -> void:
	# Limpiar lista anterior
	for child in lista_tareas.get_children():
		child.queue_free()

	var tareas = GameManager.get_tareas_asignadas()

	if tareas.is_empty():
		var label_vacio = Label.new()
		label_vacio.text = "Sin tareas asignadas."
		label_vacio.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
		lista_tareas.add_child(label_vacio)
		return

	for tarea in tareas:
		var item = _crear_item_tarea(tarea)
		lista_tareas.add_child(item)


func _crear_item_tarea(tarea: Task) -> HBoxContainer:
	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 8)

	# Icono de estado
	var icono = Label.new()
	match tarea.estado:
		Task.Estado.ACTIVA:
			icono.text = "[ ]"
			icono.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9))
		Task.Estado.COMPLETADA:
			icono.text = "[x]"
			icono.add_theme_color_override("font_color", Color(0.4, 0.8, 0.4))
		Task.Estado.FALLADA:
			icono.text = "[!]"
			icono.add_theme_color_override("font_color", Color(0.8, 0.3, 0.3))

	# Nombre de la tarea
	var nombre = Label.new()
	# Las tareas turbias muestran ??? hasta que se activan
	if tarea.tipo == Task.Tipo.TURBIA and tarea.estado == Task.Estado.ACTIVA:
		nombre.text = tarea.nombre  # El .tres ya tiene "???" como nombre
	else:
		nombre.text = tarea.nombre

	# Tachar si está completada
	if tarea.estado == Task.Estado.COMPLETADA:
		nombre.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))

	hbox.add_child(icono)
	hbox.add_child(nombre)
	return hbox


# Cuando el Jefe asigna una tarea nueva, si el papel está abierto se actualiza
func _on_tarea_activada(_tarea: Task) -> void:
	if _abierto:
		_refrescar_lista()


# Cuando se completa una tarea, actualizar el estado visual
func _on_tarea_completada(_tarea: Task) -> void:
	if _abierto:
		_refrescar_lista()
