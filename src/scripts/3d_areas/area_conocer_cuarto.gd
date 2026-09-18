extends Area3D

# Area de la habitacion del conserje: completa la tarea "conocer_cuarto"
# cuando el jugador entra (solo si la tarea esta activa).

@export var tarea_id: String = "conocer_cuarto"

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	GameManager.tarea_activada.connect(_on_tarea_activada)


func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("player"):
		_intentar_completar()


# Si la tarea se activa mientras el jugador ya esta adentro, completarla igual.
func _on_tarea_activada(tarea: Task) -> void:
	if tarea.id == tarea_id and _jugador_dentro():
		_intentar_completar()


func _jugador_dentro() -> bool:
	for body in get_overlapping_bodies():
		if body.is_in_group("player"):
			return true
	return false


func _intentar_completar() -> void:
	if GameManager.esta_tarea_activa(tarea_id):
		GameManager.completar_tarea(tarea_id)