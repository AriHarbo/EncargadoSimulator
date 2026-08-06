class_name ElevatorButton
extends Interactable

# Propiedades exportadas para configurar el botón
@export var floor_number: int = 0
@export var elevator_path: NodePath
@export var button_color: Color = Color.RED

# Referencias a nodos
@onready var elevator      = get_node_or_null(elevator_path)
@onready var button_mesh   = $ButtonMesh
@onready var button_light  = $ButtonLight
@onready var button_label  = $ButtonLabel

# Variables de estado
var is_pressed: bool = false

func _ready():
	# Configurar tipo para sistema de interacción
	type = "ElevatorButton"

	# Configurar etiqueta con número de piso
	button_label.text = str(floor_number)

	# Configurar color del botón
	if button_mesh.get_surface_override_material(0):
		button_mesh.get_surface_override_material(0).albedo_color = button_color

	# Asegurarnos que el botón esté conectado a un ascensor
	if elevator_path.is_empty() or !elevator:
		push_warning("ElevatorButton no tiene un ascensor asignado!")
		return

	# Conectar señales del ascensor para apagar el botón al llegar
	if elevator.has_signal("floor_reached"):
		elevator.floor_reached.connect(_on_elevator_floor_reached)

	# Si el ascensor ya está en este piso (inicio), asegurar que el botón esté apagado
	_update_light_state()

# Sobrescribir el método action_use de la clase Interactable
func action_use():
	# No permitir presionar si ya está en la cola o si el ascensor ya está aquí parado
	if is_pressed:
		return false
	if elevator and elevator.current_floor == floor_number and !elevator.is_moving:
		return false

	if elevator:
		_press_button()
		return true
	return false

func _press_button():
	# Marcar botón como presionado
	is_pressed = true

	# Animación visual: hundir el botón momentáneamente
	var original_position = button_mesh.position
	button_mesh.position.z -= 0.03
	button_light.light_energy = 1.0  # Iluminar fuerte al presionar

	# Reproducir sonido del botón si existe
	if has_node("ButtonSound"):
		$ButtonSound.play()

	# Solicitar el piso al ascensor (agrega a la cola, no reemplaza)
	elevator.request_floor(floor_number)

	# Restaurar posición del botón después de la animación de pulsación
	await get_tree().create_timer(0.15).timeout
	button_mesh.position = original_position

func _on_elevator_floor_reached(arrived_floor: int):
	if arrived_floor == floor_number:
		# Apagar luz y desmarcar como presionado
		is_pressed = false
		_update_light_state()

func _update_light_state():
	if is_pressed:
		button_light.light_energy = 1.0
	else:
		button_light.light_energy = 0.01  # Luz mínima apagada
