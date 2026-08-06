extends CanvasLayer

@export var panel: Panel
@export var ring_sound: AudioStream       # Asignar el .ogg del ring en el inspector
 
var _ring_player: AudioStreamPlayer
var _llamada_pendiente: BossCall = null
var _activo: bool = false
 
# Referencia al DialogoUI — se asigna desde Mapa.gd
var dialogo_ui: CanvasLayer = null
 
 
func _ready() -> void:
	_ring_player = AudioStreamPlayer.new()
	_ring_player.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(_ring_player)
 
	if ring_sound:
		_ring_player.stream = ring_sound
		_ring_player.finished.connect(func(): _ring_player.play())
 
	panel.hide()
 
 
func _input(event: InputEvent) -> void:
	if not _activo:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		if Input.is_action_just_pressed("interact"):
			atender()
 
 
# ---------------------------------------------------------------------------
# API PUBLICA
# ---------------------------------------------------------------------------
 
# Llamado desde Mapa.gd cuando el GameManager emite don_llama
func sonar(llamada: BossCall) -> void:
	_llamada_pendiente = llamada
	_activo = true
	panel.show()
	_ring_player.play()
 
 
func atender() -> void:
	if not _llamada_pendiente or not dialogo_ui:
		return
 
	_activo = false
	_ring_player.stop()
	panel.hide()
 
	var llamada = _llamada_pendiente
	_llamada_pendiente = null
 
	dialogo_ui.mostrar_dialogo(
		"???",
		llamada.lineas,
		func():
			GameManager.dia_activo = true
			GameManager.asignar_tareas(llamada.tareas_a_agregar)
	)
