extends Node3D

# ── Configuración ───────────────────────────────────────────────────────────
## Número de piso que esta puerta protege
@export var floor_number: int = 0

## Ruta al nodo raíz del ascensor (el que tiene el script elevator.gd)
@export var elevator_path: NodePath

## Tiempo de apertura/cierre de la animación (debe coincidir con AnimationPlayer)
@export var auto_close_on_elevator_leave: bool = true

# ── Referencias ─────────────────────────────────────────────────────────────
@onready var animation_player: AnimationPlayer = $AnimationPlayer

var elevator: Node3D = null
var is_open: bool = false

func _ready():
	# Obtener referencia al ascensor
	if !elevator_path.is_empty():
		elevator = get_node_or_null(elevator_path)

	if elevator == null:
		push_warning("ElevatorFloorDoor en piso %d no tiene ascensor asignado!" % floor_number)
		return

	# Conectar a las señales del ascensor
	if elevator.has_signal("floor_reached"):
		elevator.floor_reached.connect(_on_floor_reached)

	if elevator.has_signal("elevator_left_floor"):
		elevator.elevator_left_floor.connect(_on_elevator_left_floor)

	# Asegurarse de que la puerta esté cerrada al inicio
	# (a menos que el ascensor ya esté en este piso)
	if elevator.current_floor == floor_number:
		_open_door()
	else:
		_ensure_closed()

# ── Respuestas a señales del ascensor ────────────────────────────────────────
func _on_floor_reached(arrived_floor: int):
	if arrived_floor == floor_number:
		_open_door()

func _on_elevator_left_floor(left_floor: int):
	if left_floor == floor_number and auto_close_on_elevator_leave:
		_close_door()

# ── Control de la puerta ─────────────────────────────────────────────────────
func _open_door():
	if !is_open:
		is_open = true
		animation_player.play("open")

func _close_door():
	if is_open:
		is_open = false
		animation_player.play("close")

func _ensure_closed():
	is_open = false
	animation_player.play("RESET")
