extends CharacterBody3D

const SPEED = 5.0
const JUMP_VELOCITY = 4.5
var sens := 0.1
var rotation_x := 0.0

@onready var raycast = $Camera3D/RayCast3D
@onready var cam = $Camera3D
@onready var grab_point = $GrabPoint
@onready var interact_cast = $"Camera3D/RayCast_interact-areas"
@onready var hand_position = $HandPosition  # 📌 Nuevo: Nodo donde se equipa la escoba

var grabbed_object: RigidBody3D = null  # Objeto agarrado
var grab_distance: float = 3.0  # Distancia inicial del agarre
var grab_strength: float = 50.0  # Fuerza de agarre
var damping: float = 5.0  # Amortiguación para evitar oscilaciones

var busy_hand: RigidBody3D = null  # 📌 Nuevo: Para almacenar objeto equipada
var broom_on_cooldown = false  # Variable para controlar el tiempo de espera

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _process(delta: float) -> void:
	if grabbed_object:
		# Mover el punto de agarre con el mouse
		var mouse_position = get_viewport().get_mouse_position()
		var ray_origin = cam.project_ray_origin(mouse_position)
		var ray_direction = cam.project_ray_normal(mouse_position)
		grab_point.global_transform.origin = ray_origin + ray_direction * grab_distance

		# Calcular la fuerza para mover el objeto hacia el punto de agarre
		var target_position = grab_point.global_transform.origin
		var current_position = grabbed_object.global_transform.origin
		var direction = (target_position - current_position).normalized()
		var distance = target_position.distance_to(current_position)

		# Aplicar fuerza hacia el punto de agarre
		var force = direction * distance * grab_strength
		grabbed_object.apply_central_force(force)

		# Aplicar amortiguación para reducir la velocidad del objeto
		var velocity = grabbed_object.linear_velocity
		grabbed_object.apply_central_force(-velocity * damping)



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
	
	# 🧹 RECOGER ESCOBA CON "E"
	if Input.is_action_just_pressed("interact") and busy_hand == null:
		var result = raycast.get_collider()
		if result and result.is_in_group("brooms"):
			equip_broom(result)

	# 🧹 SOLTAR ESCOBA CON "Q"
	elif Input.is_action_just_pressed("drop") and busy_hand != null:
		drop_broom()
			
	# 🖱️ USAR ESCOBA CON CLIC IZQUIERDO
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		if busy_hand and busy_hand.is_in_group("brooms") and not broom_on_cooldown:
			broom_on_cooldown = true  # Activa el cooldown
			play_broom_animation()  # Reproduce la animación

			if interact_cast.is_colliding():
				var collided_object = interact_cast.get_collider()
				print("Colisionando con:", collided_object)  # Debug
				if collided_object and collided_object.is_in_group("Dirt"):
					print("Detectó suciedad!")  # Debug
					collided_object.hit()

			# Espera a que pase el tiempo de la animación antes de permitir otro clic
			await get_tree().create_timer(1).timeout  # Cambia 1 por la duración de la animación
			broom_on_cooldown = false  # Se puede volver a limpiar
					
	# AGARRE DE COSAS
	if !busy_hand:
		if event is InputEventMouseButton:
			if event.button_index == MOUSE_BUTTON_LEFT:
				if event.pressed:
					# Agarrar el objeto
					if raycast.is_colliding():
						var collided_object = raycast.get_collider()
						if collided_object.is_in_group("Trash"):
							grabbed_object = collided_object
							grab_distance = raycast.global_transform.origin.distance_to(grabbed_object.global_transform.origin)
							grabbed_object.gravity_scale = 0.0  # Desactivar gravedad temporalmente
							grabbed_object.linear_velocity = Vector3.ZERO  # Detener el movimiento
							grabbed_object.angular_velocity = Vector3.ZERO
				else:
					# Soltar el objeto
					if grabbed_object:
						grabbed_object.gravity_scale = 1.0  # Reactivar gravedad
						grabbed_object = null  # Dejar de agarrar el objeto
		
	# INTERACTUAR CON PUERTA
	if Input.is_action_just_pressed("interact"):
		var interacted = interact_cast.get_collider()
		if interacted != null and interacted.is_in_group("Interactable") and interacted.has_method("action_use"):
			interacted.action_use()
	# CERRAR EL JUEGO CON ESCAPE
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		get_tree().quit()

func equip_broom(broom: RigidBody3D) -> void:
	busy_hand = broom
	
	broom.freeze = true  
	broom.set_collision_layer_value(1, false)
	broom.set_collision_mask_value(1, false)

	broom.reparent(self)

	# 👉 Posicionamiento: más cerca del jugador y mejor alineada
	var new_transform = hand_position.global_transform
	new_transform.origin += hand_position.global_transform.basis * Vector3(0.3, -0.4, 0.5)
	broom.set_global_transform(new_transform)

	# 🔄 Rotación: inclinarla correctamente para que apunte hacia el centro
	broom.rotation_degrees = Vector3(-20, 170, 10)

func drop_broom():
	if busy_hand:
		busy_hand.reparent(get_tree().current_scene)  # Volver a la escena principal
		busy_hand.freeze = false  # Reactivar físicas
		
		# Reactivar colisiones
		busy_hand.set_collision_layer_value(1, true)
		busy_hand.set_collision_mask_value(1, true)

		busy_hand = null
	
signal broom_sweep
	
func play_broom_animation() -> void:
	if busy_hand and busy_hand.has_node("AnimationPlayer"):
		var anim_player = busy_hand.get_node("AnimationPlayer")
		if anim_player.has_animation("cleaning_animation"):
			anim_player.play("cleaning_animation")
			broom_sweep.emit()
	
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
