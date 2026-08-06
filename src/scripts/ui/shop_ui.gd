extends CanvasLayer

@export var bag_price := 20
const ORDER_BOX_SCENE = preload("res://src/scenes/props/order_box.tscn")
@export var order_spawn_point: NodePath
@export var order_delay: float = 4.0
const BAG_ORDER_QUANTITY := 10

@onready var panel = $Panel
@onready var money_label = $Panel/VBoxContainer/MoneyLabel
@onready var price_label = $Panel/VBoxContainer/PriceLabel
@onready var buy_button = $Panel/VBoxContainer/BuyButton

var _abierto := false
@onready var spawn_point: Node3D = get_node(order_spawn_point)

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	panel.hide()
	buy_button.pressed.connect(_on_buy_pressed)
	price_label.text = "Bolsas de basura x10: $%d" % bag_price


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

	if not OrderManager.can_order():
		money_label.text = "Ya tenés un pedido en camino"
		return

	if player.money < bag_price:
		money_label.text = "Not enough money"
		return

	if not player.spend_money(bag_price):
		money_label.text = "Not enough money"
		return

	OrderManager.start_order()
	money_label.text = "Pedido en camino... $%d" % player.money

	await get_tree().create_timer(order_delay).timeout

	var box = ORDER_BOX_SCENE.instantiate()
	get_tree().current_scene.add_child(box)
	box.global_transform.origin = spawn_point.global_transform.origin
	box.setup("trash_bag", BAG_ORDER_QUANTITY)
	OrderManager.current_box = box

	money_label.text = "¡Tu caja llegó! Andá a buscarla"
