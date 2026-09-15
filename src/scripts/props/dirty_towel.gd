extends RigidBody3D

# Toalla sucia agarrable y apilable. NO entra en el towel_cabinet (ese
# chequea el grupo "clean_towels") ni en estanterías (grupo "shelvable").
@export var display_name: String = "Toalla sucia"
@export var towel_mesh: Mesh   # BoxMesh placeholder desde el Inspector

@export var quantity: int = 1:
	set(value):
		quantity = value
		_update_stack_visual()

const TOWEL_HEIGHT := 0.06
const MAX_VISUAL_TOWELS := 8

@onready var stack_root: Node3D = $StackRoot

func _ready() -> void:
	add_to_group("dirty_towels")
	_update_stack_visual()

func _update_stack_visual() -> void:
	if not stack_root:
		return
	for child in stack_root.get_children():
		child.queue_free()

	var count = clamp(quantity, 1, MAX_VISUAL_TOWELS)
	for i in range(count):
		var mesh_instance := MeshInstance3D.new()
		mesh_instance.mesh = towel_mesh
		mesh_instance.position = Vector3(0, i * TOWEL_HEIGHT, 0)
		stack_root.add_child(mesh_instance)
