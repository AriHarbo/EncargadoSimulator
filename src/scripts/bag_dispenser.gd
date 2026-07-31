extends StaticBody3D

@export var max_stock := 10
var stock: int

const TRASH_BAG_SCENE = preload("res://src/scenes/trash_bag.tscn")  # path a la bolsa vacía

@onready var stock_label: Label3D = $StockLabel

var player: Node = null

func _ready() -> void:
	add_to_group("Interactable")
	stock = max_stock
	_update_label()
	stock_label.visible = false
	player = get_tree().get_first_node_in_group("player")

func _process(_delta: float) -> void:
	if not player or not stock_label:
		return

	var looking_at_it = false
	var hit = player.interact_cast.get_collider()
	if hit == self or (hit and hit.get_parent() == self):
		looking_at_it = true

	stock_label.visible = looking_at_it

func action_use() -> void:
	if not player:
		return

	if stock <= 0:
		player.show_message("Contenedor vacío")
		return

	var new_bag = TRASH_BAG_SCENE.instantiate()
	get_tree().current_scene.add_child(new_bag)
	new_bag.global_transform.origin = global_transform.origin

	var added = player.give_item(new_bag, "trash_bag")
	if not added:
		new_bag.queue_free()
		player.show_message("Inventario lleno")
		return

	stock -= 1
	_update_label()

func _update_label() -> void:
	if stock_label:
		stock_label.text = str(stock) + " bolsas"
