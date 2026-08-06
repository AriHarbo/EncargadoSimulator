extends Node

var order_active: bool = false
var current_box: Node3D = null

func can_order() -> bool:
	return not order_active

func start_order() -> void:
	order_active = true

func complete_order() -> void:
	order_active = false
	current_box = null
