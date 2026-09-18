# goal_ui.gd
extends CanvasLayer

# UI del objetivo actual: muestra un único objetivo al medio-izquierda de la
# pantalla. Se actualiza solo cuando el GameManager cambia el objetivo
# (llamadas del Don) o cuando el jugador clickea una tarea en el taskboard
# (GameManager.set_objetivo). Es meramente visual: no bloquea nada.
#
# Tambien soporta un modo "sub-objetivos": las areas de limpieza de
# habitaciones muestran la lista de subtareas con sus contadores (ej.
# "Poner toallas limpias 0/2"). Mientras ese modo está activo, ignora los
# cambios de objetivo del GameManager.
#
# Cuando una tarea se completa (señal tarea_completada) muestra el objetivo
# checkeado ("✓ ... — Completado") durante un momento y luego oculta el panel.

const TIEMPO_ANIMACION_COMPLETADA := 1.6   # segundos que queda visible el check

var _modo_subobjetivos: bool = false
var _modo_completada: bool = false
var _labels_subobjetivos: Array[Label] = []

@onready var panel: Panel = $Panel
@onready var objetivo_label: Label = $Panel/VBoxContainer/ObjetivoLabel

var _timer_completada: Timer

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	add_to_group("goal_ui")
	GameManager.objetivo_cambiado.connect(_on_objetivo_cambiado)
	GameManager.tarea_completada.connect(_on_tarea_completada)

	_timer_completada = Timer.new()
	_timer_completada.one_shot = true
	_timer_completada.wait_time = TIEMPO_ANIMACION_COMPLETADA
	_timer_completada.process_callback = Timer.TIMER_PROCESS_IDLE
	_timer_completada.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(_timer_completada)
	_timer_completada.timeout.connect(_on_completada_timeout)

	_actualizar(GameManager.objetivo_actual)

func _on_objetivo_cambiado(texto: String) -> void:
	if _modo_subobjetivos or _modo_completada:
		return
	_actualizar(texto)

func _actualizar(texto: String) -> void:
	if texto == "":
		panel.hide()
		return
	objetivo_label.text = texto
	panel.show()

# ---------------------------------------------------------------------------
# TAREA COMPLETADA (check momentaneo y ocultado)
# ---------------------------------------------------------------------------

func _on_tarea_completada(tarea: Task) -> void:
	# Si estabamos en modo sub-objetivos, salimos para mostrar el check
	if _modo_subobjetivos:
		_modo_subobjetivos = false
		_limpiar_labels()

	_modo_completada = true
	objetivo_label.text = "✓ %s — Completado" % tarea.nombre
	objetivo_label.add_theme_color_override("font_color", Color(0.4, 0.8, 0.4))
	panel.custom_minimum_size = Vector2(236, 80)
	panel.show()
	_timer_completada.start()

func _on_completada_timeout() -> void:
	_modo_completada = false
	objetivo_label.remove_theme_color_override("font_color")
	panel.hide()

func _cancelar_completada() -> void:
	_modo_completada = false
	_timer_completada.stop()
	objetivo_label.remove_theme_color_override("font_color")

# ---------------------------------------------------------------------------
# MODO SUB-OBJETIVOS (usado por area_limpieza_habitacion.gd)
# ---------------------------------------------------------------------------

# Titulo = nombre de la task (ej. "Limpiar habitacion 1"). items = lineas con
# formato "Etiqueta  X/Y". Vuelve a dibujar la lista completa en cada llamada.
func mostrar_subobjetivos(titulo: String, items: Array[String]) -> void:
	_cancelar_completada()
	_modo_subobjetivos = true
	_limpiar_labels()
	objetivo_label.text = titulo
	for texto in items:
		var label := Label.new()
		label.text = "\u2022 " + texto
		label.add_theme_font_size_override("font_size", 15)
		label.add_theme_color_override("font_color", Color(1, 1, 1, 0.95))
		$Panel/VBoxContainer.add_child(label)
		_labels_subobjetivos.append(label)
	panel.custom_minimum_size = Vector2(300, 60 + items.size() * 24)
	panel.show()

func ocultar_subobjetivos() -> void:
	if not _modo_subobjetivos:
		return
	_modo_subobjetivos = false
	_limpiar_labels()
	panel.custom_minimum_size = Vector2(236, 80)
	_actualizar(GameManager.objetivo_actual)

func _limpiar_labels() -> void:
	for label in _labels_subobjetivos:
		if is_instance_valid(label):
			label.queue_free()
	_labels_subobjetivos.clear()
