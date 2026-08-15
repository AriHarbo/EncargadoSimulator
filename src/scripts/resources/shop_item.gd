extends Resource
class_name ShopItem

@export var nombre: String = ""
@export var item_type: String = ""   # debe matchear las keys de ITEM_SCENES en order_box.gd
@export var precio: int = 0
@export var cantidad: int = 1
@export var icono: Texture2D          # opcional, usamos uno genérico si está vacío
