# lavarropas_boton.gd
extends StaticBody3D

# Botón "Iniciar lavado" del lavarropas. Es el ÚNICO nodo que arranca el
# lavado; la carga y descarga de toallas se hace en la InteractArea grande
# (lavarropas.gd). Tiene que ser HIJO de Lavarropas, hermano de InteractArea.
var machine: Node = null

func _ready() -> void:
	add_to_group("Interactable")
	machine = get_parent().get_node("InteractArea")

func get_interact_hint(_player) -> String:
	if machine.washing:
		return "[Lavando... %ds]" % int(ceil(machine.wash_timer))
	if machine.stored_dirty_quantity > 0:
		return "[E] Iniciar lavado (%d toallas)" % machine.stored_dirty_quantity
	return ""

func action_use() -> void:
	machine.start_wash()
