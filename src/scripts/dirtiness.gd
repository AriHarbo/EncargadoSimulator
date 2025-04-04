extends Node3D

@export var max_hits: int = 3  # Cantidad de golpes necesarios para limpiar
var current_hits: int = 0  # Contador de golpes

func hit():
	current_hits += 1

	var scale_factor = 1.0 - (current_hits * 0.3)  # Reducir la escala
	scale = Vector3(scale_factor, scale_factor, scale_factor)

	if current_hits >= max_hits:
		queue_free()  # Eliminar la suciedad al tercer golpe
