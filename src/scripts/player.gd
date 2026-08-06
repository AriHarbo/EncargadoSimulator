extends CharacterBody3D

const SPEED = 5.0
const JUMP_VELOCITY = 4.5
const CAMERA_TRANSITION_TIME := 0.6
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
@onready var bag_fill_bar = $UI/BagFillBar
@onready var interact_hint = $UI/InteractHint
@onready var money_label = $UI/MoneyLabel

# MONEY
@export var money := 100

# VARIABLES PARA AGARRE DE OBJETOS
var grabbed_object: RigidBody3D = null
var grab_distance: float = 3.0
# VARIABLES ÍTEM EQUIPADO ACTIVO
var equipped_item: RigidBody3D = null   # el nodo físico en HandPosition
var held_box: RigidBody3D = null
var equipped_type: String = ""          # "broom", "mop", o ""

# VARIABLES COOLDOWN USO
var tool_on_cooldown := false

# VARIABLES AGACHARSE
const CROUCH_SPEED_MULT := 0.3   # 70% más lento
const CROUCH_COLLISION_HEIGHT := 0.7
var is_crouching := false
var crouch_cam_offset := 0.0

# VARIABLES COYOTE JUMP
const COYOTE_TIME := 0.12        # Segundos de gracia tras caer de una plataforma
var coyote_timer := 0.0

@onready var collision_shape: CollisionShape3D = $CollisionShape3D
@onready var capsule_shape: CapsuleShape3D = collision_shape.shape
var normal_collision_height := 1.62
var normal_collision_y := 0.0

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

#VARIABLES RECOGER BASURA
const FULL_TRASH_BAG_SCENE = preload("res://src/scenes/trash.tscn")
var current_bag: RigidBody3D = null

# Para el bucket movible
var bucket_in_hand: Node3D = null           # El bucket cuando está siendo cargado
var bucket_preview: MeshInstance3D = null   # La preview transparente
var placing_bucket: bool = false            # Si estamos en modo colocación
var bucket_scene: PackedScene = null 

# Distancia maxima para interactuar con el bucket
const BUCKET_HOLD_TIME: float = 0.6        # Segundos que hay que mantener E
var bucket_hold_timer: float = 0.0
var holding_e_on_bucket: bool = false

var showing_message := false

# Camera blending for minigame transitions
var _blend_camera: Camera3D = null
var _blend_tween: Tween = null

signal broom_sweep

@onready var order_box_marker = $Camera3D/OrderBoxMarker

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	base_camera_y = cam.position.y
	normal_collision_height = capsule_shape.height
	normal_collision_y = collision_shape.position.y
	add_to_group("player")
	interact_hint.visible = false
	_update_money_label()

# ─── MONEY ────────────────────────────────────────────────────────────────────

func add_money(amount: int) -> void:
	money += amount
	_update_money_label()

func spend_money(amount: int) -> bool:
	if money < amount:
		return false
	money -= amount
	_update_money_label()
	return true

func _update_money_label() -> void:
	if money_label:
		money_label.text = "$%d" % money

func _physics_process(delta: float) -> void:
	if get_tree().get_first_node_in_group("minigame_active"):
		interact_hint.visible = false
		return

	# Coyote jump: mantener el timer mientras estuvo en el suelo recientemente
	if is_on_floor():
		coyote_timer = COYOTE_TIME
	else:
		coyote_timer = max(coyote_timer - delta, 0.0)
		velocity += get_gravity() * delta

	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY
	_update_crouch(delta)
	movement(delta)
	move_and_slide()
	_update_walk_bob(delta)
	_handle_grabbed_object(delta)
	_update_interact_hint()
	_update_bucket_preview()
	_handle_bucket_hold(delta)

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
	# While a minigame is active, ignore all player input (the minigame handles its own keys)
	if get_tree().get_first_node_in_group("minigame_active"):
		return

	# Mouse look
	if event is InputEventMouseMotion:
		rotate_y(deg_to_rad(-event.relative.x * sens))
		rotation_x += deg_to_rad(-event.relative.y * sens)
		rotation_x = clamp(rotation_x, deg_to_rad(-90), deg_to_rad(90))
		cam.rotation.x = rotation_x

	# ESC
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		get_tree().quit()
		
	# Modo colocación de bucket
	if placing_bucket:
		if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			_place_bucket()
			get_viewport().set_input_as_handled()
			return
		if Input.is_action_just_pressed("interact"):
			_cancel_bucket_placement()
			get_viewport().set_input_as_handled()
			return
	
	# E → intentar recoger herramienta o interactuar
	if Input.is_action_just_pressed("interact"):
		# — Recoger herramientas del piso —
		var hit = raycast.get_collider()
		if hit:
			if hit.is_in_group("brooms"):
				_pick_up_tool(hit, "broom")
				get_viewport().set_input_as_handled()
				return
			elif hit.is_in_group("mops"):
				_pick_up_tool(hit, "mop")
				get_viewport().set_input_as_handled()
				return
			elif hit.is_in_group("trash_bags"):
				_pick_up_tool(hit, "trash_bag")
				get_viewport().set_input_as_handled()
				return
			# — Recoger basura con la bolsa equipada —
			elif hit.is_in_group("TrashItem") and equipped_type == "trash_bag":
				_collect_trash_with_bag(hit)
				get_viewport().set_input_as_handled()
				return
			elif hit.is_in_group("bulbs"):
				var bulb_type = "burnt_bulb" if hit.is_in_group("burnt_bulbs") else "bulb"
				_pick_up_tool(hit, bulb_type)
				get_viewport().set_input_as_handled()
				return
		var interacted = interact_cast.get_collider()
		if interacted and interacted.is_in_group("Interactable"):
			var target = interacted
			if not target.has_method("action_use") and target.get_parent().has_method("action_use"):
				target = target.get_parent()
			if target.has_method("action_use"):
				target.action_use()
				get_viewport().set_input_as_handled()
	
	if Input.is_action_just_pressed("drop"):
		drop_current_tool()
	
		# Interactuables genéricos
		var interacted = interact_cast.get_collider()
		if interacted and interacted.is_in_group("Interactable"):
			var target = interacted
			if not target.has_method("action_use") and target.get_parent().has_method("action_use"):
				target = target.get_parent()
			if target.has_method("action_use"):
				target.action_use()
				
	# Click izquierdo → usar herramienta o agarrar basura
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			if equipped_item and not tool_on_cooldown:
				_use_equipped_tool()
			elif not equipped_item and not held_box:
				_try_grab_trash()
		else:
			_release_grabbed_object()

	# Rueda del mouse → ajustar distancia grab
	if grabbed_object and event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			grab_distance = clamp(grab_distance + 0.2, 1.0, 3.0)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			grab_distance = clamp(grab_distance - 0.2, 1.0, 3.0)

# ─── CAMERA TRANSITIONS ───────────────────────────────────────────────────────

func enter_minigame_camera(target: Camera3D) -> void:
	_tween_to_camera(target)

func exit_minigame_camera(on_finished: Callable = Callable()) -> void:
	_tween_to_camera(cam, on_finished)

func _tween_to_camera(target: Camera3D, on_finished: Callable = Callable()) -> void:
	# Cancel any previous blend still in progress
	if _blend_tween and _blend_tween.is_valid():
		_blend_tween.kill()
	if is_instance_valid(_blend_camera):
		_blend_camera.queue_free()

	var current_cam: Camera3D = get_viewport().get_camera_3d()
	var from_transform := current_cam.global_transform
	var from_fov := current_cam.fov

	var temp := Camera3D.new()
	get_tree().current_scene.add_child(temp)
	temp.global_transform = from_transform
	temp.fov = from_fov
	temp.current = true
	_blend_camera = temp

	var tw := create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	_blend_tween = tw
	tw.tween_property(temp, "global_transform", target.global_transform, CAMERA_TRANSITION_TIME)
	tw.parallel().tween_property(temp, "fov", target.fov, CAMERA_TRANSITION_TIME)
	tw.tween_callback(func():
		if is_instance_valid(temp):
			temp.queue_free()
		if _blend_camera == temp:
			_blend_camera = null
		_blend_tween = null
		target.current = true
		if on_finished.is_valid():
			on_finished.call()
	)

# ─── RECOGER / SOLTAR HERRAMIENTAS ────────────────────────────────────────────
func give_item(item_node: RigidBody3D, type: String) -> bool:
	if hotbar.has_item(item_node):
		return true

	var added = hotbar.try_add_item(item_node, type)
	if not added:
		return false

	if hotbar.has_item(item_node):
		# Se agregó como nuevo ítem físico (no se stackeó): prepararlo
		item_node.freeze = true
		item_node.visible = false
		item_node.set_collision_layer_value(1, false)
		item_node.set_collision_mask_value(1, false)

		var slot_index = hotbar.get_slot_index(item_node)
		if slot_index == hotbar.selected_slot and not equipped_item:
			_attach_to_hand(item_node, type)
	else:
		# Se stackeó en un ítem existente: este nodo físico sobra
		item_node.queue_free()

	return true

# Consume UNA unidad del tipo indicado del hotbar. Devuelve false si no hay stock.
func consume_item(item_type: String) -> bool:
	for i in range(hotbar.hotbar_items.size()):
		var entry = hotbar.hotbar_items[i]
		if entry and entry["type"] == item_type:
			var node = entry["node"]
			var qty = node.get("quantity")
			if qty != null and qty > 1:
				node.quantity = qty - 1
				hotbar.refresh_slots()
			else:
				if equipped_item == node:
					_detach_from_hand()
				hotbar.remove_item_from_slot(i)
				node.queue_free()
			return true
	return false

func _pick_up_tool(tool_node: RigidBody3D, type: String) -> void:
	give_item(tool_node, type)

# Llamado por la hotbar al cambiar de slot
func equip_item(tool_node, type: String) -> void:
	# Desconectar el ítem actual de la mano (volver invisible / desactivar)
	if equipped_item:
		_detach_from_hand()

	if tool_node == null:
		return

	_attach_to_hand(tool_node, type)

func _attach_to_hand(tool_node: RigidBody3D, type: String) -> void:
	if held_box:
		drop_held_box()
	
	equipped_item = tool_node
	equipped_type = type

	tool_node.freeze = true
	tool_node.set_collision_layer_value(1, false)
	tool_node.set_collision_mask_value(1, false)

	var target_marker = order_box_marker if type == "order_box" else hand_position
	tool_node.reparent(hand_position)
	tool_node.transform = Transform3D.IDENTITY
	tool_node.visible = true
	
	if type == "trash_bag":
		bag_fill_bar.show_bar()
		bag_fill_bar.update_fill(tool_node.get_fill_ratio())
	else:
		bag_fill_bar.hide_bar()

func _detach_from_hand() -> void:
	if not equipped_item:
		return
	bag_fill_bar.hide_bar()
	equipped_item.visible = false
	equipped_item.reparent(get_tree().current_scene)
	equipped_item.freeze = true
	equipped_item = null
	equipped_type = ""

func pick_up_box(box: RigidBody3D) -> void:
	if held_box:
		return
	if equipped_item:
		_detach_from_hand()   # no tener herramienta + caja al mismo tiempo

	held_box = box
	box.freeze = true
	box.set_collision_layer_value(1, false)
	box.set_collision_mask_value(1, false)
	box.reparent(order_box_marker)
	box.transform = Transform3D.IDENTITY
	box.visible = true

func drop_held_box(consumed: bool = false) -> void:
	if not held_box:
		return
	var box = held_box
	held_box = null

	if consumed:
		box.queue_free()
		return

	box.reparent(get_tree().current_scene)
	var drop_offset = -cam.global_transform.basis.z * 1.2 + Vector3(0, 0.3, 0)
	box.global_transform.origin = cam.global_transform.origin + drop_offset
	box.freeze = false
	box.visible = true
	box.set_collision_layer_value(1, true)
	box.set_collision_mask_value(1, true)
	box.apply_central_impulse(-cam.global_transform.basis.z * 2.0)

# ─── DROP HERRAMIENTA ─────────────────────────────────────────────────────────

func drop_current_tool() -> void:
	if held_box and not equipped_item:
		drop_held_box()
		return
	if not equipped_item:
		hotbar.remove_item_from_slot(hotbar.selected_slot)
		return

	var qty = equipped_item.get("quantity")
	if qty != null and qty > 1:
		# Solo tirar UNA copia, quedarte con el resto en mano
		equipped_item.quantity = qty - 1
		hotbar.refresh_slots()
		_spawn_dropped_copy(equipped_item)
		return

	# Comportamiento original: queda 1 (o el item no tiene quantity) → tirar todo
	var item = equipped_item
	var slot = hotbar.selected_slot

	if equipped_type == "trash_bag":
		bag_fill_bar.hide_bar()

	equipped_item = null
	equipped_type = ""

	item.reparent(get_tree().current_scene)

	var drop_offset = -cam.global_transform.basis.z * 1.2 + Vector3(0, 0.3, 0)
	item.global_transform.origin = cam.global_transform.origin + drop_offset

	item.freeze = false
	item.visible = true
	item.set_collision_layer_value(1, true)
	item.set_collision_mask_value(1, true)
	item.apply_central_impulse(-cam.global_transform.basis.z * 2.0)

	hotbar.remove_item_from_slot(slot)

func _spawn_dropped_copy(source_item: Node) -> void:
	if source_item.scene_file_path == "":
		push_warning("No se pudo clonar el item: scene_file_path vacío")
		return

	var copy = load(source_item.scene_file_path).instantiate()
	get_tree().current_scene.add_child(copy)

	var drop_offset = -cam.global_transform.basis.z * 1.2 + Vector3(0, 0.3, 0)
	copy.global_transform.origin = cam.global_transform.origin + drop_offset

	copy.freeze = false
	copy.visible = true
	copy.set_collision_layer_value(1, true)
	copy.set_collision_mask_value(1, true)
	copy.apply_central_impulse(-cam.global_transform.basis.z * 2.0)

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
		cam.position.y = base_camera_y + crouch_cam_offset + sin(bob_time) * bob_amount * (0.5 if is_crouching else 1.0)
		if sonidos_pasos.size() > 0:
			paso_timer -= delta
			if paso_timer <= 0.0:
				audio.stream = sonidos_pasos[randi() % sonidos_pasos.size()]
				audio.play()
				paso_timer = paso_intervalo
	else:
		cam.position.y = lerp(cam.position.y, base_camera_y + crouch_cam_offset, delta * 10.0)
		paso_timer = 0.0

# ─── MOVIMIENTO ───────────────────────────────────────────────────────────────

func movement(delta: float) -> void:
	var input_dir = Vector3.ZERO
	if Input.is_action_pressed("move_up"):    input_dir -= transform.basis.z
	if Input.is_action_pressed("move_down"):  input_dir += transform.basis.z
	if Input.is_action_pressed("move_left"):  input_dir -= transform.basis.x
	if Input.is_action_pressed("move_right"): input_dir += transform.basis.x

	input_dir = input_dir.normalized()

	if is_on_floor():
		# En el suelo: aplicar velocidad directamente con el multiplicador de agacharse
		var speed = SPEED * (CROUCH_SPEED_MULT if is_crouching else 1.0)
		velocity.x = input_dir.x * speed
		velocity.z = input_dir.z * speed
	else:
		# En el aire: ignorar el multiplicador de crouch para preservar la inercia del salto.
		# Solo se aplica un control aéreo suave que no mata la velocidad horizontal.
		var air_speed = SPEED
		var air_control := 6.0
		velocity.x = lerp(velocity.x, input_dir.x * air_speed, air_control * delta)
		velocity.z = lerp(velocity.z, input_dir.z * air_speed, air_control * delta)

	if Input.is_action_just_pressed("jump") and coyote_timer > 0.0:
		velocity.y = JUMP_VELOCITY
		coyote_timer = 0.0  # Consumir el coyote time para no poder saltar dos veces

# ─── AGACHARSE ─────────────────────────────────────────────────────────────────

func _update_crouch(delta: float) -> void:
	var want_crouch = Input.is_action_pressed("crouch")
	if want_crouch:
		is_crouching = true
	elif is_crouching and _can_stand():
		is_crouching = false

	var target_height = CROUCH_COLLISION_HEIGHT if is_crouching else normal_collision_height
	var target_y = normal_collision_y - (normal_collision_height - target_height) * 0.5
	capsule_shape.height = target_height
	collision_shape.position.y = target_y

	crouch_cam_offset = lerp(crouch_cam_offset, -0.45 if is_crouching else 0.0, delta * 12.0)

func _can_stand() -> bool:
	var head = global_position + Vector3(0, collision_shape.position.y + capsule_shape.height * 0.5, 0)
	var clearance = normal_collision_height - capsule_shape.height + 0.1
	var query = PhysicsRayQueryParameters3D.create(head, head + Vector3(0, clearance, 0))
	query.exclude = [self]
	return not get_world_3d().direct_space_state.intersect_ray(query)

# ─── BOLSA DE BASURA ──────────────────────────────────────────────────────────

func _collect_trash_with_bag(trash_node: Node) -> void:
	if not equipped_item or equipped_type != "trash_bag":
		return
	if not equipped_item.can_collect():
		return

	# Conectar señal bag_full si no está conectada aún
	if not equipped_item.bag_full.is_connected(_on_bag_full):
		equipped_item.bag_full.connect(_on_bag_full)

	trash_node.collect()
	equipped_item.collect_item()

	if equipped_item:
		bag_fill_bar.update_fill(equipped_item.get_fill_ratio())

func _on_bag_full(bag_node: RigidBody3D) -> void:
	var full_bag = FULL_TRASH_BAG_SCENE.instantiate()
	get_tree().current_scene.add_child(full_bag)
	full_bag.global_transform.origin = global_transform.origin + (-transform.basis.z * 1.0) + Vector3(0, 0.3, 0)

	if bag_node.quantity > 1:
		bag_node.quantity -= 1
		bag_node.reset_fill()
		hotbar.refresh_slots()
		bag_fill_bar.update_fill(bag_node.get_fill_ratio())
	else:
		bag_fill_bar.hide_bar()
		var slot = hotbar.selected_slot
		equipped_item = null
		equipped_type = ""
		hotbar.remove_item_from_slot(slot)
		bag_node.queue_free()
	
func _update_interact_hint() -> void:
	if showing_message:
		return
	# Si estamos en modo colocación de bucket, mostrar hint de colocación
	if placing_bucket:
		interact_hint.text = "[Click] Colocar — [E] Cancelar"
		interact_hint.visible = true
		return
 
	var hit = raycast.get_collider()
	var interacted = interact_cast.get_collider()
 
	# Chequear raycast principal (herramientas)
	if hit:
		if hit.is_in_group("brooms"):
			interact_hint.text = "[E] Agarrar escoba"
			interact_hint.visible = true
			return
		elif hit.is_in_group("mops"):
			interact_hint.text = "[E] Agarrar mopa"
			interact_hint.visible = true
			return
		elif hit.is_in_group("trash_bags"):
			interact_hint.text = "[E] Agarrar bolsa"
			interact_hint.visible = true
			return
		elif hit.is_in_group("TrashItem") and equipped_type == "trash_bag":
			interact_hint.text = "[Click] Recoger basura"
			interact_hint.visible = true
			return
		elif hit.is_in_group("bulbs"):
			interact_hint.text = "[E] Agarrar bombilla"
			interact_hint.visible = true
			return
		elif hit.is_in_group("Trash"):
			interact_hint.text = "[Click] Agarrar"
			interact_hint.visible = true
			return
 
	# Chequear interact_cast (interactables)
	if interacted:
		var target = interacted
		if not target.has_method("action_use") and target.get_parent().has_method("action_use"):
			target = target.get_parent()

		if target.has_method("action_use"):
			if target.has_method("get_interact_hint"):
				var hint_text: String = target.get_interact_hint(self)
				if hint_text == "":
					interact_hint.visible = false
				else:
					interact_hint.text = hint_text
					interact_hint.visible = true
				return
			elif target.is_in_group("bucket"):
				if equipped_type == "mop":
					interact_hint.text = "[E] Lavar mopa"
				else:
					interact_hint.text = "[E] Agarrar balde"
				interact_hint.visible = true
				return
			elif target.is_in_group("luz_sockets"):
				interact_hint.text = "[E] Cambiar bombilla"
				interact_hint.visible = true
				return
			elif target.is_in_group("Interactable"):
				interact_hint.text = "[E] Interactuar"
				interact_hint.visible = true
				return
 
	# Si no hay nada interactuable, ocultar
	interact_hint.visible = false
 
 
# ─── BUCKET MOVIBLE ───────────────────────────────────────────────────────────
 
func _handle_bucket_hold(delta: float) -> void:
	# Si estamos en modo colocación, no procesar el hold
	if placing_bucket:
		return
 
	var interacted = interact_cast.get_collider()
	var target = interacted
	if target and not target.is_in_group("bucket") and target.get_parent().is_in_group("bucket"):
		target = target.get_parent()
 
	# Detectar si estamos apuntando al bucket y manteniendo E
	if target and target.is_in_group("bucket") and Input.is_action_pressed("interact") and equipped_type != "mop":
		holding_e_on_bucket = true
		bucket_hold_timer += delta
 
		if bucket_hold_timer >= BUCKET_HOLD_TIME:
			_pick_up_bucket(target.get_parent() if not target.is_in_group("bucket") else target)
			bucket_hold_timer = 0.0
			holding_e_on_bucket = false
	else:
		if holding_e_on_bucket:
			bucket_hold_timer = 0.0
			holding_e_on_bucket = false
 
 
func _pick_up_bucket(bucket_node: Node3D) -> void:
	bucket_in_hand = bucket_node
	placing_bucket = true
 
	# Ocultar el bucket real
	bucket_node.visible = false
	# Desactivar colisión del bucket
	for child in bucket_node.get_children():
		if child is CollisionShape3D or child is Area3D:
			child.set_deferred("monitoring", false) if child is Area3D else null
			child.set_deferred("disabled", true) if child is CollisionShape3D else null
 
	# Crear preview transparente
	_create_bucket_preview(bucket_node)
 
 
func _create_bucket_preview(bucket_node: Node3D) -> void:
	# Duplicar la mesh del bucket para la preview
	bucket_preview = MeshInstance3D.new()
	
	# Buscar el MeshInstance3D del bucket original
	for child in bucket_node.get_children():
		if child is MeshInstance3D:
			bucket_preview.mesh = child.mesh
			break
 
	# Material transparente azulado
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.3, 0.6, 1.0, 0.4)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	bucket_preview.set_surface_override_material(0, mat)
 
	get_tree().current_scene.add_child(bucket_preview)
 
 
func _update_bucket_preview() -> void:
	if not placing_bucket or not bucket_preview:
		return
 
	# Raycast hacia el suelo desde la cámara
	var space_state = get_world_3d().direct_space_state
	var cam_origin = cam.global_transform.origin
	var cam_forward = -cam.global_transform.basis.z
	
	var query = PhysicsRayQueryParameters3D.create(
		cam_origin,
		cam_origin + cam_forward * 5.0
	)
	query.exclude = [self]
	var result = space_state.intersect_ray(query)
 
	if result:
		# Siempre pegado al suelo — solo usar la Y del punto de impacto
		var pos = result.position
		bucket_preview.global_transform.origin = Vector3(pos.x, pos.y + 0.3, pos.z)
		bucket_preview.global_transform.basis = Basis.IDENTITY
		bucket_preview.visible = true
	else:
		bucket_preview.visible = false
 
 
func _place_bucket() -> void:
	if not placing_bucket or not bucket_in_hand:
		return
 
	if bucket_preview and bucket_preview.visible:
		# Colocar el bucket en la posición del preview
		bucket_in_hand.global_transform.origin = bucket_preview.global_transform.origin
		bucket_in_hand.visible = true
 
		# Reactivar colisiones
		for child in bucket_in_hand.get_children():
			if child is CollisionShape3D:
				child.set_deferred("disabled", false)
			elif child is Area3D:
				child.set_deferred("monitoring", true)
 
	# Limpiar preview
	if bucket_preview:
		bucket_preview.queue_free()
		bucket_preview = null
 
	bucket_in_hand = null
	placing_bucket = false
 
 
func _cancel_bucket_placement() -> void:
	# Restaurar bucket en su posición original
	if bucket_in_hand:
		bucket_in_hand.visible = true
		for child in bucket_in_hand.get_children():
			if child is CollisionShape3D:
				child.set_deferred("disabled", false)
			elif child is Area3D:
				child.set_deferred("monitoring", true)
 
	if bucket_preview:
		bucket_preview.queue_free()
		bucket_preview = null
 
	bucket_in_hand = null
	placing_bucket = false

func show_message(text: String, duration: float = 1.5) -> void:
	showing_message = true
	interact_hint.text = text
	interact_hint.visible = true
	await get_tree().create_timer(duration).timeout
	showing_message = false

func take_equipped_item() -> RigidBody3D:
	if not equipped_item:
		return null
	var item = equipped_item
	var slot = hotbar.selected_slot
	if equipped_type == "trash_bag":
		bag_fill_bar.hide_bar()
	equipped_item = null
	equipped_type = ""
	hotbar.remove_item_from_slot(slot)
	return item

func discard_equipped_item() -> void:
	if not equipped_item:
		return
	var item = equipped_item
	var slot = hotbar.selected_slot
	equipped_item = null
	equipped_type = ""
	bag_fill_bar.hide_bar()
	hotbar.remove_item_from_slot(slot)
	item.queue_free()
