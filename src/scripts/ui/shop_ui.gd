extends CanvasLayer

const ORDER_SLOT_SCENE = preload("res://src/scenes/ui/order_slot.tscn")
const ORDER_BOX_SCENE = preload("res://src/scenes/props/order_box.tscn")

@export var items: Array[ShopItem] = []
@export var order_delay: float = 4.0

@onready var panel = $Panel
@onready var money_label = $Panel/VBoxContainer/MoneyLabel
@onready var slots_container = $Panel/VBoxContainer/SlotsContainer

var _abierto := false
var order_spawn_point: Node3D 

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	panel.hide()
	_generar_slots()

func _generar_slots() -> void:
	for item in items:
		var slot = ORDER_SLOT_SCENE.instantiate()
		slots_container.add_child(slot)
		slot.setup(item)
		slot.comprar_pressed.connect(_on_buy_pressed)

func esta_abierto() -> bool:
	return _abierto

func abrir() -> void:
	_abierto = true
	_refrescar_money()
	panel.show()

func cerrar() -> void:
	_abierto = false
	panel.hide()

func _refrescar_money() -> void:
	var player = get_tree().get_first_node_in_group("player")
	if player:
		money_label.text = "Money: $%d" % player.money

func _on_buy_pressed(item: ShopItem) -> void:
	var player = get_tree().get_first_node_in_group("player")
	if not player:
		return
	if not OrderManager.can_order():
		money_label.text = "Ya tenés un pedido en camino"
		return
	if player.money < item.precio:
		money_label.text = "Not enough money"
		return
	if not player.spend_money(item.precio):
		money_label.text = "Not enough money"
		return
	if order_spawn_point == null:
		push_warning("ShopUI: order_spawn_point no fue asignado")
		return

	OrderManager.start_order()
	money_label.text = "Pedido en camino... $%d" % player.money
	await get_tree().create_timer(order_delay).timeout

	var box = ORDER_BOX_SCENE.instantiate()
	get_tree().current_scene.add_child(box)
	box.global_transform.origin = order_spawn_point.global_transform.origin
	box.setup(item.item_type, item.cantidad)
	OrderManager.current_box = box
	money_label.text = "¡Tu caja llegó! Andá a buscarla"
