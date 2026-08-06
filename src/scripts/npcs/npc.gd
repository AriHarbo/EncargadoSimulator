extends Interactable  # ya tiene grupo "Interactable"

@export var npc_name: String = "NPC"
@export var npc_id: String = ""              # ej: "npc_juan" - unico por NPC
@export var lineas_dialogo: PackedStringArray = []
@export var lineas_dialogo_post: PackedStringArray = ["Ya hablamos, andá a lo tuyo."]
@export var tarea_a_completar: String = ""    # ej: "tarea_01_presentaciones"

var _tarea_completada: bool = false

func action_use() -> void:
	var lineas: PackedStringArray = lineas_dialogo_post if _tarea_completada else lineas_dialogo
	DialogoUi.mostrar_dialogo(npc_name, lineas, _on_dialogo_terminado)

func _on_dialogo_terminado() -> void:
	if _tarea_completada:
		return
	if tarea_a_completar != "":
		_tarea_completada = true
		GameManager.registrar_dialogo_npc(tarea_a_completar, npc_id)
