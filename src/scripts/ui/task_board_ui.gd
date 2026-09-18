extends CanvasLayer

@export var panel: Panel
@export var lista_tareas: VBoxContainer
@export var hint_cerrar: Label

# Escena de un item de tarea — la creamos por código así que no necesita escena separada
var _abierto: bool = false
var _primera_vez: bool = true
var _hbox_objetivo: HBoxContainer = null

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	print("panel: ", panel)
	print("lista_tareas: ", lista_tareas)
	print("hint_cerrar: ", hint_cerrar)
	panel.hide()
	# Escuchar cuando el Jefe asigna tareas nuevas para actualizar el papel
	GameManager.tarea_activada.connect(_on_tarea_activada)
	GameManager.tarea_completada.connect(_on_tarea_completada)


func _unhandled_input(event: InputEvent) -> void:
	if not _abierto:
		return
	if event.is_action_pressed("interact") or event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		cerrar()


# ---------------------------------------------------------------------------
# API PUBLICA
# ---------------------------------------------------------------------------

func abrir() -> void:
	if _primera_vez:
		_primera_vez = false
		GameManager.asignar_tareas(["limpiar_hab1", "limpiar_hab2"])
	
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
	_hbox_objetivo = null

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

	# Clickear una tarea la marca como objetivo actual (solo visual).
	hbox.mouse_filter = Control.MOUSE_FILTER_STOP
	hbox.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	hbox.gui_input.connect(_on_item_clic.bind(tarea, hbox))

	if tarea.nombre == GameManager.objetivo_actual:
		_hbox_objetivo = hbox
		hbox.modulate = Color(1, 1, 0.65)

	return hbox


func _on_item_clic(event: InputEvent, tarea: Task, hbox: HBoxContainer) -> void:
	if not (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT):
		return

	# Clickear la tarea ya marcada la desmarca y oculta la UI de objetivo.
	if GameManager.objetivo_actual == tarea.nombre:
		GameManager.set_objetivo("")
		_highlight_objetivo(null)
		return

	GameManager.set_objetivo(tarea.nombre)
	_highlight_objetivo(hbox)


func _highlight_objetivo(hbox: HBoxContainer) -> void:
	if _hbox_objetivo:
		_hbox_objetivo.modulate = Color(1, 1, 1)
	_hbox_objetivo = hbox
	if hbox:
		hbox.modulate = Color(1, 1, 0.65)


# Cuando el Jefe asigna una tarea nueva, si el papel está abierto se actualiza
func _on_tarea_activada(_tarea: Task) -> void:
	if _abierto:
		_refrescar_lista()


# Cuando se completa una tarea, actualizar el estado visual
func _on_tarea_completada(_tarea: Task) -> void:
	if _abierto:
		_refrescar_lista()
