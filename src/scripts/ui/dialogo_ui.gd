extends CanvasLayer

@export var panel: Panel
@export var label_nombre: Label
@export var label_texto: RichTextLabel
@export var label_continuar: Label
@export var sonido_murmullos: AudioStream

@export var segundos_por_caracter: float = 0.04

var _lineas: Array[String] = []
var _linea_actual: int = 0
var _escribiendo: bool = false
var _texto_completo: String = ""
var _caracter_actual: int = 0
var _callback_al_terminar: Callable

var _timer: Timer
var _audio: AudioStreamPlayer


func _ready() -> void:
	# Crear Timer como hijo del CanvasLayer (process_mode Already en Always)
	_timer = Timer.new()
	_timer.one_shot = false
	_timer.wait_time = segundos_por_caracter
	_timer.process_callback = Timer.TIMER_PROCESS_IDLE
	_timer.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(_timer)
	_timer.timeout.connect(_on_timer_timeout)

	# Crear AudioStreamPlayer
	_audio = AudioStreamPlayer.new()
	_audio.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(_audio)
	if sonido_murmullos:
		_audio.stream = sonido_murmullos

	panel.hide()


func _input(event: InputEvent) -> void:
	if not panel.visible:
		return
	if event.is_action_pressed("interact"):
		if _escribiendo:
			_saltar_typewriter()
		else:
			_siguiente_linea()


# ---------------------------------------------------------------------------
# API PUBLICA
# ---------------------------------------------------------------------------

func mostrar_dialogo(nombre: String, lineas: Array[String], callback: Callable = Callable()) -> void:
	_lineas = lineas
	_linea_actual = 0
	_callback_al_terminar = callback

	label_nombre.text = nombre
	label_continuar.hide()
	panel.show()

	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	get_tree().paused = true

	_escribir_linea_actual()


func cerrar() -> void:
	_timer.stop()
	_audio.stop()
	panel.hide()
	_escribiendo = false
	get_tree().paused = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	if _callback_al_terminar.is_valid():
		_callback_al_terminar.call()


# ---------------------------------------------------------------------------
# LOGICA INTERNA
# ---------------------------------------------------------------------------

func _escribir_linea_actual() -> void:
	if _linea_actual >= _lineas.size():
		_terminar_dialogo()
		return

	_texto_completo = _lineas[_linea_actual]
	_caracter_actual = 0
	label_texto.text = ""
	label_continuar.hide()
	_escribiendo = true

	if sonido_murmullos:
		_audio.play()

	_timer.start()


func _on_timer_timeout() -> void:
	if _caracter_actual >= _texto_completo.length():
		_typewriter_termino()
		return

	_caracter_actual += 1
	label_texto.text = _texto_completo.substr(0, _caracter_actual)


func _typewriter_termino() -> void:
	_timer.stop()
	_audio.stop()
	_escribiendo = false
	label_texto.text = _texto_completo
	label_continuar.show()


func _saltar_typewriter() -> void:
	_timer.stop()
	_audio.stop()
	_escribiendo = false
	label_texto.text = _texto_completo
	label_continuar.show()


func _siguiente_linea() -> void:
	_linea_actual += 1
	label_continuar.hide()
	_escribir_linea_actual()


func _terminar_dialogo() -> void:
	cerrar()
