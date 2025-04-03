extends Node3D

# Señales
signal floor_reached(floor_number)

# Variables exportadas para configuración desde el editor
@export var floors: Array[int] = [0, 1, 2, 3]  # Pisos disponibles
@export var floor_heights: Array[float] = [0.0, 5.0, 10.0, 15.0]  # Altura de cada piso
@export var elevator_speed: float = 2.0  # Velocidad del ascensor
@export var door_animation_time: float = 1.0  # Tiempo que tarda la animación de la puerta

# Referencias a nodos
@onready var elevator_platform = $ElevatorPlatform
@onready var buttons_container = $ElevatorPlatform/ButtonsPanel
@onready var door_animation_player = $ElevatorPlatform/DoorAnimationPlayer
@onready var floor_display = $ElevatorPlatform/FloorDisplay

# Variables de estado
var current_floor: int = 0
var target_floor: int = 0
var is_moving: bool = false
var doors_open: bool = true
var player_inside: bool = false

func _ready():
	# Configurar botones para cada piso
	_setup_floor_buttons()
	
	# Mostrar piso actual
	#_update_floor_display()

func _process(delta):
	if is_moving:
		# Mover el ascensor hacia el piso objetivo
		var target_height = floor_heights[floors.find(target_floor)]
		var current_height = elevator_platform.position.y
		var direction = 1 if target_height > current_height else -1
		
		# Calcular movimiento
		var movement = elevator_speed * delta * direction
		
		# Verificar si llegamos al destino
		if abs(target_height - current_height) <= abs(movement):
			elevator_platform.position.y = target_height
			_arrive_at_floor()
		else:
			elevator_platform.position.y += movement

func _setup_floor_buttons():
	# Crear botones para cada piso
	for floor_num in floors:
		var button = Button.new()
		button.text = str(floor_num)
		button.pressed.connect(_on_floor_button_pressed.bind(floor_num))
		#buttons_container.add_child(button)

func _on_floor_button_pressed(floor_num):
	if current_floor == floor_num or is_moving:
		return
	
	target_floor = floor_num
	
	# Cerrar puertas antes de moverse
	if doors_open:
		_close_doors()
		await door_animation_player.animation_finished
	
	# Iniciar movimiento
	is_moving = true

func _arrive_at_floor():
	is_moving = false
	current_floor = target_floor
	#_update_floor_display()
	#emit_signal("floor_reached", current_floor)
	
	# Abrir puertas
	_open_doors()

func _open_doors():
	if !doors_open:
		door_animation_player.play_backwards("close_doors")
		doors_open = true

func _close_doors():
	if doors_open:
		door_animation_player.play("close_doors")
		doors_open = false

#func _update_floor_display():
	#floor_display.text = str(current_floor)

# Detector de área para saber cuando el jugador está dentro
func _on_elevator_area_body_entered(body):
	if body.is_in_group("player"):
		player_inside = true

func _on_elevator_area_body_exited(body):
	if body.is_in_group("player"):
		player_inside = false

# Llamar al ascensor desde afuera (para botones externos)
func call_elevator(floor_num):
	if !is_moving and current_floor != floor_num:
		target_floor = floor_num
		
		# Cerrar puertas si están abiertas
		if doors_open:
			_close_doors()
			await door_animation_player.animation_finished
		
		# Iniciar movimiento
		is_moving = true
