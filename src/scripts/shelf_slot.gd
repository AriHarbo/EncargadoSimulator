extends StaticBody3D

## Slot individual de una estantería.
## - Con las manos vacías (o con OTRO tipo de item) + E sobre un slot con foco
##   guardado -> te lo pasa a la mano (mismo camino que escobas/mopas).
## - Con un foco nuevo equipado + E sobre un slot vacío -> lo deja guardado ahí.

@export var accepted_type: String = "bulb_new"
@export var display_name: String = "bombilla" 

@onready var mesh_anchor: Node3D = $MeshAnchor

var stored_item: RigidBody3D = null

func _ready() -> void:
	add_to_group("Interactable")

func is_empty() -> bool:
	return stored_item == null

## Llamado automáticamente por interact_cast + E, desde Player._input.
func action_use() -> void:
	var player = get_tree().get_first_node_in_group("player")
	if not player:
		return
	if is_empty():
		_place_from_hand(player)
	else:
		_give_to_hand(player)

func _place_from_hand(player) -> void:
	if player.equipped_type != accepted_type or not player.equipped_item:
		return
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

func _give_to_hand(player) -> void:
	var node = stored_item
	stored_item = null
	node.reparent(get_tree().current_scene)
	if not player.give_item(node, accepted_type):
		node.reparent(mesh_anchor)
		node.transform = Transform3D.IDENTITY
		stored_item = node

func get_interact_hint(player) -> String:
	if is_empty():
		if player.equipped_type == accepted_type and player.equipped_item:
			return "[E] Dejar " + display_name
		return "" # manos vacías o item que no corresponde -> nada
	else:
		return "[E] Agarrar " + display_name
