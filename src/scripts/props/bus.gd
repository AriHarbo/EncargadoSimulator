extends Node3D

# Autobus que aparece estacionado en la parada al iniciar el dia,
# hace la animacion de irse (avanza por la calle) y desaparece.

@export var sonido_bus: AudioStream
@export var velocidad: float = 8.0
@export var direccion: Vector3 = Vector3(0, 0, 1)
@export var distancia_partida: float = 16.0
@export var demora_inicial: float = 1.5

@onready var _audio: AudioStreamPlayer3D = $AudioStreamPlayer3D

var _pos_inicial: Vector3
var _en_marcha: bool = false

func _ready() -> void:
	_pos_inicial = global_position
	if sonido_bus:
		_audio.stream = sonido_bus
	if _audio.stream:
		_audio.play()
	get_tree().create_timer(demora_inicial).timeout.connect(_iniciar_partida)


func _iniciar_partida() -> void:
	_en_marcha = true


func _physics_process(delta: float) -> void:
	if not _en_marcha:
		return
	var por = global_position.distance_to(_pos_inicial)
	global_position += direccion * velocidad * delta
	por = global_position.distance_to(_pos_inicial)
	if por >= distancia_partida:
		_en_marcha = false
		queue_free()
	elif por > distancia_partida * 0.7:
		var t: float = (por - distancia_partida * 0.7) / (distancia_partida * 0.3)
		scale = Vector3.ONE * lerpf(1.0, 0.001, t)