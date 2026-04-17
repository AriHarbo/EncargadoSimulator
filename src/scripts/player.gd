extends CharacterBody3D

const SPEED = 5.0
const JUMP_VELOCITY = 4.5
var sens := 0.1
var rotation_x := 0.0

@onready var raycast = $Camera3D/RayCast3D
@onready var cam = $Camera3D
@onready var grab_point = $Camera3D/GrabPoint
@onready var interact_cast = $"Camera3D/RayCast_interact-areas"
@onready var hand_position = $Camera3D/HandPosition
@onready var audio = $AudioStreamPlayer3D
@onready var audioI = $AudioInteractables
@onready var hotbar = $UI/HotbarUI  

# VARIABLES PARA AGARRE DE OBJETOS
var grabbed_object: RigidBody3D = null
var grab_distance: float = 3.0

# VARIABLES ÍTEM EQUIPADO ACTIVO
var equipped_item: RigidBody3D = null   # el nodo físico en HandPosition
var equipped_type: String = ""          # "broom", "mop", o ""

# VARIABLES COOLDOWN USO
var tool_on_cooldown := false

# VARIABLES CAMINAR
var bob_time := 0.0
var bob_speed := 10.0
var bob_amount := 0.08
var base_camera_y := 0.0
var paso_timer := 0.0
var paso_intervalo := 0.4
var sonidos_pasos := [
	preload("res://sounds/step1.wav"),
	preload("res://sounds/step3.wav"),
	preload("res://sounds/step4.wav")
]

signal broom_sweep

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	base_camera_y = cam.position.y
	add_to_group("player")

func _process(delta: float) -> void:
	_handle_grabbed_object(delta)

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY
	movement(delta)
	move_and_slide()
	_update_walk_bob(delta)

# ─── GRAB ──────────────────────────────────────────────────────────────────────

func _handle_grabbed_object(delta: float) -> void:
	if not grabbed_object:
		return
	var mouse_position = get_viewport().get_mouse_position()
	var ray_origin = cam.project_ray_origin(mouse_position)
	var ray_direction = cam.project_ray_normal(mouse_position)
	grab_point.global_transform.origin = ray_origin + ray_direction * grab_distance

	var stiffness = 300.0
	var damp = 40.0
	var target_pos = grab_point.global_transform.origin
	var current_pos = grabbed_object.global_transform.origin
	var vel = grabbed_object.linear_velocity
	grabbed_object.apply_central_force((target_pos - current_pos) * stiffness + (-vel * damp))

	if Input.is_action_pressed("rotate_right"):
		grabbed_object.rotate_y(delta * 2.0)
	if Input.is_action_pressed("rotate_left"):
		grabbed_object.rotate_y(-delta * 2.0)

# ─── INPUT ─────────────────────────────────────────────────────────────────────

func _input(event: InputEvent) -> void:
	# Mouse look
	if event is InputEventMouseMotion:
		rotate_y(deg_to_rad(-event.relative.x * sens))
		rotation_x += deg_to_rad(-event.relative.y * sens)
		rotation_x = clamp(rotation_x, deg_to_rad(-90), deg_to_rad(90))
		cam.rotation.x = rotation_x

	# ESC
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		get_tree().quit()

	# E → intentar recoger herramienta o interactuar
	if Input.is_action_just_pressed("interact"):
		var hit = raycast.get_collider()
		if hit:
			if hit.is_in_group("brooms"):
				_pick_up_tool(hit, "broom")
				return
			elif hit.is_in_group("mops"):
				_pick_up_tool(hit, "mop")
				return

		# Interactuables genéricos
		var interacted = interact_cast.get_collider()
		if interacted and interacted.is_in_group("Interactable") and interacted.has_method("action_use"):
			interacted.action_use()

	# Click izquierdo → usar herramienta o agarrar basura
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			if equipped_item and not tool_on_cooldown:
				_use_equipped_tool()
			elif not equipped_item:
				_try_grab_trash()
		else:
			_release_grabbed_object()

	# Rueda del mouse → ajustar distancia grab
	if grabbed_object and event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			grab_distance = clamp(grab_distance + 0.2, 1.0, 3.0)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			grab_distance = clamp(grab_distance - 0.2, 1.0, 3.0)

# ─── RECOGER / SOLTAR HERRAMIENTAS ────────────────────────────────────────────

func _pick_up_tool(tool_node: RigidBody3D, type: String) -> void:
	# Buscar slot libre en hotbar
	var slot_index = hotbar.get_free_slot()
	if slot_index == -1:
		print("Hotbar llena")
		return

	# Guardar referencia y tipo en la hotbar
	hotbar.add_item_to_slot(slot_index, tool_node, type)

	# Si el slot libre es el activo, equipar de inmediato
	if slot_index == hotbar.selected_slot:
		_attach_to_hand(tool_node, type)

# Llamado por la hotbar al cambiar de slot
func equip_item(tool_node, type: String) -> void:
	# Desconectar el ítem actual de la mano (volver invisible / desactivar)
	if equipped_item:
		_detach_from_hand()

	if tool_node == null:
		return

	_attach_to_hand(tool_node, type)

func _attach_to_hand(tool_node: RigidBody3D, type: String) -> void:
	equipped_item = tool_node
	equipped_type = type

	tool_node.freeze = true
	tool_node.set_collision_layer_value(1, false)
	tool_node.set_collision_mask_value(1, false)
	tool_node.reparent(hand_position)
	tool_node.transform = Transform3D.IDENTITY
	tool_node.visible = true

func _detach_from_hand() -> void:
	if not equipped_item:
		return
	# Lo dejamos oculto pero en la escena, para que siga en hotbar
	equipped_item.visible = false
	# Lo sacamos de hand_position y lo ponemos en la raíz para no perderlo
	equipped_item.reparent(get_tree().current_scene)
	equipped_item.freeze = true
	equipped_item = null
	equipped_type = ""

func drop_current_tool() -> void:
	if not equipped_item:
		return
	var item = equipped_item
	var slot = hotbar.selected_slot
	equipped_item = null
	equipped_type = ""

	item.reparent(get_tree().current_scene)
	item.freeze = false
	item.set_collision_layer_value(1, true)
	item.set_collision_mask_value(1, true)
	item.visible = true
	hotbar.remove_item_from_slot(slot)

# ─── USO DE HERRAMIENTAS ───────────────────────────────────────────────────────

func _use_equipped_tool() -> void:
	match equipped_type:
		"broom":
			await _use_broom()
		"mop":
			await _use_mop()

func _use_broom() -> void:
	tool_on_cooldown = true
	_play_tool_animation(equipped_item)
	broom_sweep.emit()

	if interact_cast.is_colliding():
		var obj = interact_cast.get_collider()
		if obj and obj.is_in_group("Dirt"):
			audioI.stream = preload("res://sounds/broom_sound.wav")
			audioI.play()
			obj.hit()

	await get_tree().create_timer(0.5).timeout
	_stop_tool_animation(equipped_item)
	tool_on_cooldown = false

func _use_mop() -> void:
	if not equipped_item.has_method("can_clean"):
		return
	if not equipped_item.can_clean():
		print("La mopa está sucia, lávala en el balde")
		# Aquí podés mostrar una señal de UI
		return

	tool_on_cooldown = true
	_play_tool_animation(equipped_item)

	if interact_cast.is_colliding():
		var obj = interact_cast.get_collider()
		if obj and obj.is_in_group("BloodStain"):
			audioI.stream = preload("res://sounds/mop_sound.wav")
			audioI.play()
			obj.hit()
			equipped_item.add_dirt()   # La mopa se va ensuciando

	await get_tree().create_timer(0.5).timeout
	_stop_tool_animation(equipped_item)
	tool_on_cooldown = false

# ─── GRAB BASURA ──────────────────────────────────────────────────────────────

func _try_grab_trash() -> void:
	if raycast.is_colliding():
		var obj = raycast.get_collider()
		if obj.is_in_group("Trash"):
			grabbed_object = obj
			grab_distance = raycast.global_transform.origin.distance_to(obj.global_transform.origin)
			obj.gravity_scale = 0.0
			obj.linear_velocity = Vector3.ZERO
			obj.angular_velocity = Vector3.ZERO
			obj.angular_damp = 100.0

func _release_grabbed_object() -> void:
	if grabbed_object:
		grabbed_object.gravity_scale = 1.0
		grabbed_object.angular_damp = 1.0
		grabbed_object = null

# ─── ANIMACIONES ──────────────────────────────────────────────────────────────

func _play_tool_animation(tool_node: RigidBody3D) -> void:
	if tool_node.has_node("AnimationPlayer"):
		var ap = tool_node.get_node("AnimationPlayer")
		if ap.has_animation("cleaning_animation"):
			ap.play("cleaning_animation")

func _stop_tool_animation(tool_node: RigidBody3D) -> void:
	if tool_node and tool_node.has_node("AnimationPlayer"):
		tool_node.get_node("AnimationPlayer").stop()
		# Restaurar transform si es necesario
		tool_node.transform = Transform3D.IDENTITY

# ─── WALK BOB ─────────────────────────────────────────────────────────────────

func _update_walk_bob(delta: float) -> void:
	var moving = velocity.length() > 0.5 and is_on_floor()
	if moving:
		bob_time += delta * bob_speed
		cam.position.y = base_camera_y + sin(bob_time) * bob_amount
		if sonidos_pasos.size() > 0:
			paso_timer -= delta
			if paso_timer <= 0.0:
				audio.stream = sonidos_pasos[randi() % sonidos_pasos.size()]
				audio.play()
				paso_timer = paso_intervalo
	else:
		cam.position.y = lerp(cam.position.y, base_camera_y, delta * 10.0)
		paso_timer = 0.0

# ─── MOVIMIENTO ───────────────────────────────────────────────────────────────

func movement(delta: float) -> void:
	var input_dir = Vector3.ZERO
	if Input.is_action_pressed("move_up"):    input_dir -= transform.basis.z
	if Input.is_action_pressed("move_down"):  input_dir += transform.basis.z
	if Input.is_action_pressed("move_left"):  input_dir -= transform.basis.x
	if Input.is_action_pressed("move_right"): input_dir += transform.basis.x

	input_dir = input_dir.normalized() * SPEED
	velocity.x = input_dir.x
	velocity.z = input_dir.z

	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY
