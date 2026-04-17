extends Area3D

var trash_item = preload("res://src/scenes/trash_item.tscn")

func _ready() -> void:
	var cantidad_basuras = randi_range(1, 8)
	
	for i in cantidad_basuras:
		var suciedad = trash_item.instantiate()
		var x = randf_range(-1.0, 1.0)
		var z = randf_range(-1.0, 1.0)
		suciedad.position = Vector3(x, 0.0, z)
		suciedad.trash_type = randi_range(0, 3)
		add_child(suciedad)
