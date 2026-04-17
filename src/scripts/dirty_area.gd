extends Area3D

var dirtiness_scene = preload("res://src/scenes/dirtiness.tscn")
var blood_scene = preload("res://src/scenes/blood_stain.tscn")
var trash_area_scene = preload("res://src/scenes/trash_area.tscn")  

func _ready() -> void:
	var cantidad_dirt = randi_range(1, 10)
	var cantidad_blood = randi_range(1, 10)
	var cantidad_trash_areas = randi_range(3, 8)
	
	for i in cantidad_dirt:
		var suciedad = dirtiness_scene.instantiate()
		var x = randf_range(-10.0, 10.0)
		var z = randf_range(-10.0, 10.0)
		suciedad.position = Vector3(x, 0.7, z)
		add_child(suciedad)
	
	for i in cantidad_blood:
		var sangre = blood_scene.instantiate()
		var x = randf_range(-10.0, 10.0)
		var z = randf_range(-10.0, 10.0)
		sangre.position = Vector3(x, 0.7, z)
		add_child(sangre)
	
	for i in cantidad_trash_areas:
		var trash_area = trash_area_scene.instantiate()
		var x = randf_range(-10.0, 10.0)
		var z = randf_range(-10.0, 10.0)
		trash_area.position = Vector3(x, 2, z)
		add_child(trash_area)
