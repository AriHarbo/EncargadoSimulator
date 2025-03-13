extends Node3D

var trash_can_scene = preload("res://src/assets/trash_can.tscn")
var trash_scene = preload("res://src/assets/trash.tscn")

func _ready():
	# Instanciar y colocar el tacho de basura
	var trash_can_instance = trash_can_scene.instantiate()
	add_child(trash_can_instance)
	trash_can_instance.position = Vector3(10,1.5, 0)

	for i in range(5):  # 5 basuras como ejemplo
		var trash_instance = trash_scene.instantiate()
		add_child(trash_instance)
		trash_instance.position = Vector3(randf_range(-10, 10), 1, randf_range(-10, 10))
		trash_instance.add_to_group("basura")
