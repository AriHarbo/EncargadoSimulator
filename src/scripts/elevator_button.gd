class_name ElevatorButton
extends Interactable

# Propiedades exportadas para configurar el botón
@export var floor_number: int = 0
@export var elevator_path: NodePath
@export var button_color: Color = Color.RED

# Referencias a nodos
@onready var elevator = get_node_or_null(elevator_path)
@onready var button_mesh = $ButtonMesh
@onready var button_light = $ButtonLight
@onready var button_label = $ButtonLabel

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
		push_warning("ElevatorButton en no tiene un ascensor asignado!")

# Sobrescribir el método action_use de la clase Interactable
func action_use():
	if !is_pressed and elevator:
		_press_button()
		return true
	return false

func _press_button():
	# Marcar botón como presionado
	is_pressed = true
	
	# Animación visual de presionado
	var original_position = button_mesh.position
	button_mesh.position.z -= 0.03  # Hundir el botón
	button_light.light_energy = 2.0  # Iluminar el botón
	
	# Reproducir sonido (opcional)
	if has_node("ButtonSound"):
		$ButtonSound.play()
	
	# Llamar al ascensor
	elevator.call_elevator(floor_number)
	
	# Restaurar botón después de un corto tiempo
	await get_tree().create_timer(0.3).timeout
	button_mesh.position = original_position
	
	# Mantener la luz encendida hasta que el ascensor llegue
	if elevator.has_signal("floor_reached"):
		elevator.floor_reached.connect(_on_elevator_floor_reached)

func _on_elevator_floor_reached(arrived_floor):
	if arrived_floor == floor_number:
		# Apagar luz cuando el ascensor llegue a este piso
		button_light.light_energy = 0.2
		is_pressed = false
		
		# Desconectar señal para evitar acumulación de conexiones
		if elevator.floor_reached.is_connected(_on_elevator_floor_reached):
			elevator.floor_reached.disconnect(_on_elevator_floor_reached)
