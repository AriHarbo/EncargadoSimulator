extends RigidBody3D

const MAX_TRASH := 5
var current_trash := 0

# Señal para que el player sepa que se llenó
signal bag_full(bag_node)

func _ready() -> void:
	add_to_group("trash_bags")

func can_collect() -> bool:
	return current_trash < MAX_TRASH

func collect_item() -> void:
	current_trash += 1
	if current_trash >= MAX_TRASH:
		bag_full.emit(self)

func get_fill_ratio() -> float:
	return float(current_trash) / float(MAX_TRASH)
