extends StaticBody3D

# Toallas limpias apiladas que el jugador puede guardar/sacar de a UNA con E.
const TOWEL_SCENE := preload("res://src/scenes/props/clean_towel.tscn")
const MAX_CAPACITY := 4

# Señales para que otros sistemas (areas de limpieza de habitaciones) puedan
# seguir el progreso de toallas guardadas en este armario.
signal toalla_guardada
signal toalla_sacada

@onready var mesh_anchor: Node3D = $MeshAnchor

var stored_quantity: int = 0
var stored_towel_node: RigidBody3D = null

func _ready() -> void:
	add_to_group("Interactable")

func is_full() -> bool:
	return stored_quantity >= MAX_CAPACITY

func is_empty() -> bool:
	return stored_quantity <= 0

func _holding_towel(player) -> bool:
	return player.equipped_item != null and player.equipped_item.is_in_group("clean_towels")

func get_interact_hint(player) -> String:
	var holding := _holding_towel(player)

	if holding and is_full():
		return "[Estante lleno (%d/%d)]" % [stored_quantity, MAX_CAPACITY]
	elif holding:
		return "[E] Dejar toalla (%d/%d)" % [stored_quantity, MAX_CAPACITY]
	elif not is_empty():
		return "[E] Agarrar toalla (%d/%d)" % [stored_quantity, MAX_CAPACITY]
	return ""

func action_use() -> void:
	var player = get_tree().get_first_node_in_group("player")
	if not player:
		return

	var holding := _holding_towel(player)

	if holding and not is_full():
		_deposit_one(player)
	elif not holding and not is_empty():
		_take_one(player)

func _deposit_one(player) -> void:
	var item = player.equipped_item
	var qty: int = item.get("quantity")

	stored_quantity += 1
	_refresh_visual()

	if qty > 1:
		item.quantity = qty - 1
		player.hotbar.refresh_slots()
	else:
		player.discard_equipped_item()

	toalla_guardada.emit()

func _take_one(player) -> void:
	var towel := _new_towel(1)
	get_tree().current_scene.add_child(towel)
	if not player.give_item(towel, "clean_towel"):
		towel.queue_free()
		player.show_message("No podes cargar más toallas")
		return

	stored_quantity -= 1
	_refresh_visual()

	toalla_sacada.emit()

func _new_towel(qty: int) -> RigidBody3D:
	var towel: RigidBody3D = TOWEL_SCENE.instantiate()
	towel.freeze = true
	towel.visible = false
	towel.quantity = qty
	return towel

func _refresh_visual() -> void:
	if stored_quantity <= 0:
		if stored_towel_node:
			stored_towel_node.queue_free()
			stored_towel_node = null
		return

	if not stored_towel_node:
		stored_towel_node = TOWEL_SCENE.instantiate()
		stored_towel_node.freeze = true
		stored_towel_node.visible = true
		stored_towel_node.set_collision_layer_value(1, false)
		stored_towel_node.set_collision_mask_value(1, false)
		mesh_anchor.add_child(stored_towel_node)
		stored_towel_node.transform = Transform3D.IDENTITY

	stored_towel_node.quantity = stored_quantity
