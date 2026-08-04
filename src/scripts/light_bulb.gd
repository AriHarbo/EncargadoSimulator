extends RigidBody3D

var quantity := 1
@export var is_burnt := false

func _ready() -> void:
	add_to_group("bulbs")

# Called by the trash bag when this bulb is collected like trash
func collect() -> void:
	queue_free()
