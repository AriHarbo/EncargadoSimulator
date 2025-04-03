extends Area3D

func _ready():
	add_to_group("Dirt")  # Asegurar que el área está en el grupo

func hit():
	var dirtiness_node = get_parent()  # Obtener el Node3D padre
	if dirtiness_node:
		dirtiness_node.hit()  # Llamar la función hit() en el Node3D
