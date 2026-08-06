extends RigidBody3D

signal trash_collected

func _ready():
	# Asegúrate de que el objeto esté en el grupo "Trash"
	add_to_group("Trash")

func collect():
	# Reproducir una animación o sonido antes de eliminar el objeto
	# Ejemplo: $AnimationPlayer.play("collect")
	emit_signal("trash_collected")
	queue_free()
