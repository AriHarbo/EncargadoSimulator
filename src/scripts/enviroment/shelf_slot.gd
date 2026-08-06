extends StaticBody3D

@onready var mesh_anchor: Node3D = $MeshAnchor

var stored_item: RigidBody3D = null
var stored_item_type: String = ""   # el "type" de hotbar del item guardado

func _ready() -> void:
	add_to_group("Interactable")

func is_empty() -> bool:
	return stored_item == null

func get_interact_hint(player) -> String:
	if is_empty():
		if player.equipped_item and player.equipped_item.is_in_group("shelvable"):
			return "[E] Dejar " + player.equipped_item.display_name
		return ""
	else:
		return "[E] Agarrar " + stored_item.display_name

func action_use() -> void:
	var player = get_tree().get_first_node_in_group("player")
	if not player:
		return
	if is_empty():
		_place_from_hand(player)
	else:
		_give_to_hand(player)

func _place_from_hand(player) -> void:
	if not player.equipped_item or not player.equipped_item.is_in_group("shelvable"):
		return
	var item_type: String = player.equipped_type
	var item_node: RigidBody3D = player.take_equipped_item()
	if item_node == null:
		return
	item_node.reparent(mesh_anchor)
	item_node.transform = Transform3D.IDENTITY
	item_node.freeze = true
	item_node.visible = true
	item_node.set_collision_layer_value(1, false)
	item_node.set_collision_mask_value(1, false)
	stored_item = item_node
	stored_item_type = item_type

func _give_to_hand(player) -> void:
	var node = stored_item
	var type = stored_item_type
	stored_item = null
	stored_item_type = ""
	node.reparent(get_tree().current_scene)
	if not player.give_item(node, type):
		node.reparent(mesh_anchor)
		node.transform = Transform3D.IDENTITY
		stored_item = node
		stored_item_type = type
