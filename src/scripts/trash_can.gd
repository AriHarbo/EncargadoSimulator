extends Area3D

func _ready():
	connect("body_entered", _on_body_entered)

func _on_body_entered(body):
	if body.is_in_group("player") and body.has_trash():
		body.drop_trash()  # Eliminar la basura del jugador
