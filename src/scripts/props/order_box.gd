extends RigidBody3D

@onready var collision: CollisionShape3D = $CollisionShape3D
@onready var label: Label3D = $ItemLabel   # opcional, para debug/UX

var item_type: String = ""
var bag_count: int = 0

func setup(type: String, amount: int) -> void:
	item_type = type
	bag_count = amount
	_update_label()

func _ready() -> void:
	add_to_group("Interactable")
	freeze = true

func action_use() -> void:
	var player = get_tree().get_first_node_in_group("player")
	if not player:
		return
	if player.held_box:
		return
	player.pick_up_box(self)

func get_interact_hint(player) -> String:
	if player.held_box:
		return ""
	return "[E] Agarrar caja"

func consume(amount: int) -> int:
	var taken = min(amount, bag_count)
	bag_count -= taken
	_update_label()
	return taken

func is_empty() -> bool:
	return bag_count <= 0

func _update_label() -> void:
	if label:
		label.text = "%s x%d" % [item_type, bag_count]
