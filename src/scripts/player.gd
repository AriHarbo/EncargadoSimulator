extends CharacterBody3D

const SPEED = 5.0
const JUMP_VELOCITY = 4.5
var sens := 0.1
var rotation_x := 0.0

@onready var raycast = $Camera3D/RayCast3D
@onready var cam = $Camera3D
var initial_raycast_rotation: Vector3

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _process(delta: float) -> void:
	pass

func _physics_process(delta: float) -> void:
	# Aplicar gravedad si no está en el suelo
	if not is_on_floor():
		velocity += get_gravity() * delta
	
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY  
	movement(delta)
	move_and_slide()


func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		rotate_y(deg_to_rad(-event.relative.x * sens))  # Rotación horizontal
		rotation_x += deg_to_rad(-event.relative.y * sens)  # Rotación vertical
		rotation_x = clamp(rotation_x, deg_to_rad(-90), deg_to_rad(90))  # Limitar visión arriba/abajo
		cam.rotation.x = rotation_x
	
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		print("click!")
		if raycast.is_colliding():
			print("raycast colliding!")
			var collided_object = raycast.get_collider()
			print("objeto: ", collided_object)
			if collided_object.is_in_group("Trash"):
				collided_object.queue_free()
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		get_tree().quit()
func movement(delta: float) -> void:
	var input_dir = Vector3.ZERO
	if Input.is_action_pressed("move_up"):
		input_dir -= transform.basis.z
	if Input.is_action_pressed("move_down"):
		input_dir += transform.basis.z
	if Input.is_action_pressed("move_left"):
		input_dir -= transform.basis.x
	if Input.is_action_pressed("move_right"):
		input_dir += transform.basis.x
	
	input_dir = input_dir.normalized() * SPEED
	velocity.x = input_dir.x
	velocity.z = input_dir.z
	
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY
