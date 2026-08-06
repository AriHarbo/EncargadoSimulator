extends Area3D

func _ready():
	# Conecta la señal body_entered a la función on_body_entered
	connect("body_entered", Callable(self, "on_body_entered"))

func on_body_entered(body: Node3D):
	# Verifica si el cuerpo que entró es un objeto Trash
	print("detectando objeto")
	if body.is_in_group("Trash"):
		# Borra el objeto Trash
		body.queue_free()
