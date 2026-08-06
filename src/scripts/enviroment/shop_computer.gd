extends StaticBody3D

# La UI de compras que se abre al interactuar — asignar en el inspector
@export var shop_ui: CanvasLayer


func action_use() -> void:
	if shop_ui:
		shop_ui.abrir()
