extends RigidBody3D

const MAX_DIRT = 3
var current_dirt := 0

@onready var head_mesh = $MopMesh/Head

# Colores según suciedad
var color_clean := Color("#E0D8C0")
var color_dirty := Color("#8B0000")

func can_clean() -> bool:
	return current_dirt < MAX_DIRT

func add_dirt() -> void:
	current_dirt += 1
	_update_color()
	print("Mopa suciedad: %d/%d" % [current_dirt, MAX_DIRT])
	if current_dirt >= MAX_DIRT:
		print("¡Mopa llena! Lávala en el balde.")

func wash() -> void:
	current_dirt = 0
	_update_color()
	print("Mopa limpia.")

func get_dirt_ratio() -> float:
	return float(current_dirt) / float(MAX_DIRT)

func _update_color() -> void:
	var ratio = get_dirt_ratio()
	var color = color_clean.lerp(color_dirty, ratio)
	var mat = head_mesh.get_surface_override_material(0)
	if mat == null:
		mat = StandardMaterial3D.new()
		head_mesh.set_surface_override_material(0, mat)
	mat.albedo_color = color
