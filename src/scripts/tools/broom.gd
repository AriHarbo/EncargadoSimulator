extends RigidBody3D

func _physics_process(_delta: float) -> void:
	if global_position.y < -5.0:
		global_position = Vector3(0, 1.0, 0)
		linear_velocity = Vector3.ZERO
		angular_velocity = Vector3.ZERO
