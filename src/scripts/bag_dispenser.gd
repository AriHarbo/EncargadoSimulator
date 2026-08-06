extends StaticBody3D

@export var max_stock := 10
var stock: int = 10   # arranca vacío, se llena con las cajas
const TRASH_BAG_SCENE = preload("res://src/scenes/trash_bag.tscn")

@onready var stock_label: Label3D = $StockLabel
var player: Node = null

func _ready() -> void:
	add_to_group("Interactable")
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

	if player.held_box:
		_fill_from_box(player.held_box)
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

func get_interact_hint(p) -> String:
	if p.held_box:
		if p.held_box.item_type != "trash_bag":
			return "Esta caja no es para acá"
		return "[E] Vaciar caja"
	if stock <= 0:
		return "[E] Contenedor vacío"
	return "[E] Agarrar bolsa"

func _fill_from_box(box: Node3D) -> void:
	if box.item_type != "trash_bag":
		player.show_message("Esta caja no es para acá")
		return

	var space = max_stock - stock
	if space <= 0:
		player.show_message("Contenedor lleno")
		return

	var taken = box.consume(space)
	stock += taken
	_update_label()

	if box.is_empty():
		player.drop_held_box(true)
		OrderManager.complete_order()
		player.show_message("¡Contenedor recargado!")
	else:
		player.show_message("Recargado: quedan %d bolsas en la caja" % box.bag_count)
		
func _update_label() -> void:
	if stock_label:
		stock_label.text = str(stock) + " bolsas"
