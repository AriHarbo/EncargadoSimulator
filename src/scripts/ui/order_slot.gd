extends HBoxContainer
class_name OrderSlot

signal comprar_pressed(item: ShopItem)

const GENERIC_ICON := preload("res://icon.svg")  # cambiá esto por tu ícono genérico cuando tengas uno

@onready var icon_rect: TextureRect = $Icon
@onready var name_label: Label = $Info/NameLabel
@onready var detail_label: Label = $Info/DetailLabel
@onready var buy_button: Button = $BuyButton

var item: ShopItem

func _ready() -> void:
	buy_button.pressed.connect(func(): comprar_pressed.emit(item))

func setup(shop_item: ShopItem) -> void:
	item = shop_item
	name_label.text = item.nombre
	detail_label.text = "x%d — $%d" % [item.cantidad, item.precio]
	icon_rect.texture = item.icono if item.icono else GENERIC_ICON
