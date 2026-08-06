extends Node3D

# Señales
signal floor_reached(floor_number)
signal elevator_left_floor(floor_number)

# Variables exportadas para configuración desde el editor
@export var floors: Array[int] = [0, 1, 2, 3]        # Pisos disponibles
@export var floor_heights: Array[float] = [0.0, 5.0, 10.0, 15.0]  # Altura de cada piso
@export var elevator_speed: float = 2.0               # Velocidad del ascensor (unidades/segundo)
@export var door_wait_time: float = 2.0               # Tiempo que espera con puertas abiertas en cada piso

# Referencias a nodos
@onready var elevator_platform    = $ElevatorPlatform
@onready var door_animation_player = $ElevatorPlatform/DoorAnimationPlayer
@onready var floor_display        = $ElevatorPlatform/FloorDisplay
@onready var elevator_sound       = $ElevatorPlatform/ElevatorSound

# Variables de estado
var current_floor: int = 0
var is_moving: bool    = false
var doors_open: bool   = true
var player_inside: bool = false

# Cola de pisos pendientes (procesada en orden inteligente)
var floor_queue: Array[int] = []

# Dirección actual: 1 = subiendo, -1 = bajando, 0 = parado
var current_direction: int = 0

func _ready():
	_update_floor_display()

func _process(delta):
	if is_moving:
		var idx = floors.find(current_floor)
		# Calcular el siguiente destino actual (primer elemento de la cola)
		if floor_queue.is_empty():
			_stop_elevator()
			return

		var next_floor  = floor_queue[0]
		var next_idx    = floors.find(next_floor)
		var target_height  = floor_heights[next_idx]
		var current_height = elevator_platform.position.y
		var direction   = 1 if target_height > current_height else -1

		var movement = elevator_speed * delta * direction

		if abs(target_height - current_height) <= abs(movement):
			# Llegamos a este piso
			elevator_platform.position.y = target_height
			floor_queue.pop_front()
			_arrive_at_floor(next_floor)
		else:
			elevator_platform.position.y += movement

# ── Solicitar un piso desde un botón interior ──────────────────────────────
func request_floor(floor_num: int):
	# Ignorar si ya está en la cola o si es el piso actual parado
	if floor_num in floor_queue:
		return
	if floor_num == current_floor and !is_moving:
		return

	floor_queue.append(floor_num)
	_sort_queue()

	if !is_moving:
		_start_movement()

# ── Llamar al ascensor desde botones externos (pasillo) ────────────────────
func call_elevator(floor_num: int):
	request_floor(floor_num)

# ── Ordenar la cola de forma inteligente según dirección ──────────────────
# Lógica: si el ascensor está subiendo, primero atiende los pisos mayores al
# actual en orden ascendente, luego los menores en orden descendente.
# Si está bajando, primero los menores en orden descendente, luego los mayores.
# Si está parado, la dirección la define el primer piso pedido.
func _sort_queue():
	if floor_queue.is_empty():
		return

	# Determinar dirección si está parado
	if current_direction == 0 and !floor_queue.is_empty():
		current_direction = 1 if floor_queue[0] > current_floor else -1

	var above: Array[int] = []
	var below: Array[int] = []

	for f in floor_queue:
		if f > current_floor:
			above.append(f)
		elif f < current_floor:
			below.append(f)

	above.sort()          # ascendente
	below.sort()
	below.reverse()       # descendente

	if current_direction >= 0:
		# Subiendo: primero los de arriba, luego los de abajo
		floor_queue = above + below
	else:
		# Bajando: primero los de abajo, luego los de arriba
		floor_queue = below + above

# ── Iniciar movimiento ─────────────────────────────────────────────────────
func _start_movement():
	if floor_queue.is_empty():
		return

	# Determinar dirección
	var next_floor = floor_queue[0]
	current_direction = 1 if next_floor > current_floor else -1

	# Cerrar puertas si están abiertas
	if doors_open:
		_close_doors()
		await door_animation_player.animation_finished

	# Emitir señal de que el ascensor sale del piso actual
	emit_signal("elevator_left_floor", current_floor)

	# Activar sonido de movimiento
	if elevator_sound and elevator_sound.stream:
		elevator_sound.play()

	is_moving = true

# ── Llegada a un piso ──────────────────────────────────────────────────────
func _arrive_at_floor(arrived_floor: int):
	is_moving = false
	current_floor = arrived_floor

	# Actualizar dirección o pararla si la cola está vacía
	if floor_queue.is_empty():
		current_direction = 0

	_update_floor_display()

	# Detener sonido de movimiento
	if elevator_sound:
		elevator_sound.stop()

	emit_signal("floor_reached", current_floor)

	# Abrir puertas y esperar
	_open_doors()
	await door_animation_player.animation_finished
	await get_tree().create_timer(door_wait_time).timeout

	# Si quedan pisos en la cola, continuar
	if !floor_queue.is_empty():
		_start_movement()

# ── Detener el ascensor (cola vacía mientras se movía) ─────────────────────
func _stop_elevator():
	is_moving = false
	current_direction = 0
	if elevator_sound:
		elevator_sound.stop()

# ── Puertas del ascensor ───────────────────────────────────────────────────
func _open_doors():
	if !doors_open:
		door_animation_player.play_backwards("close_doors")
		doors_open = true

func _close_doors():
	if doors_open:
		door_animation_player.play("close_doors")
		doors_open = false

# ── Display de piso ────────────────────────────────────────────────────────
func _update_floor_display():
	if floor_display:
		floor_display.text = "PB" if current_floor == 0 else str(current_floor)

# ── Detección del jugador dentro del ascensor ──────────────────────────────
func _on_elevator_area_body_entered(body):
	if body.is_in_group("player"):
		player_inside = true

func _on_elevator_area_body_exited(body):
	if body.is_in_group("player"):
		player_inside = false
