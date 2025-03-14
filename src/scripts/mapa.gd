extends Node3D


var trash_scene = preload("res://src/scenes/trash.tscn")

func _ready():
	for i in range(5):  # 5 basuras como ejemplo
		var trash_instance = trash_scene.instantiate()
		add_child(trash_instance)
		trash_instance.position = Vector3(randf_range(-10, 10), 1, randf_range(-10, 10))
		trash_instance.add_to_group("basura")
