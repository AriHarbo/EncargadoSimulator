extends CanvasLayer

@export var bag_price := 20

@onready var panel = $Panel
@onready var money_label = $Panel/VBoxContainer/MoneyLabel
@onready var price_label = $Panel/VBoxContainer/PriceLabel
@onready var buy_button = $Panel/VBoxContainer/BuyButton

const TRASH_BAG_SCENE = preload("res://src/scenes/trash_bag.tscn")

var _abierto := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	panel.hide()
	buy_button.pressed.connect(_on_buy_pressed)
	price_label.text = "Trash bag: $%d" % bag_price


func _unhandled_input(event: InputEvent) -> void:
	if not _abierto:
		return
	if event.is_action_pressed("interact") or event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		cerrar()


func abrir() -> void:
	_abierto = true
	_refrescar_money()
	panel.show()
	get_tree().paused = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func cerrar() -> void:
	_abierto = false
	panel.hide()
	get_tree().paused = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _refrescar_money() -> void:
	var player = get_tree().get_first_node_in_group("player")
	if player:
		money_label.text = "Money: $%d" % player.money


func _on_buy_pressed() -> void:
	var player = get_tree().get_first_node_in_group("player")
	if not player:
		return

	if player.money < bag_price:
		money_label.text = "Not enough money"
		return

	var new_bag = TRASH_BAG_SCENE.instantiate()
	get_tree().current_scene.add_child(new_bag)
	new_bag.global_transform.origin = player.global_transform.origin

	if not player.give_item(new_bag, "trash_bag"):
		new_bag.queue_free()
		money_label.text = "Inventory full"
		return

	player.spend_money(bag_price)
	money_label.text = "Bought! Money: $%d" % player.money
