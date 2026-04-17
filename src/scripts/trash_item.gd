extends RigidBody3D

enum TrashType { CAN, COFFEE_CUP, PAPER, PLASTIC }

@export var trash_type: TrashType = TrashType.CAN

@onready var mesh = $MeshInstance3D
@onready var collision = $CollisionShape3D

# Colores identificadores por tipo (placeholder)
const TYPE_COLORS = {
	TrashType.CAN:        Color(0.8, 0.2, 0.2),   # rojo
	TrashType.COFFEE_CUP: Color(0.5, 0.3, 0.1),   # marrón
	TrashType.PAPER:      Color(0.9, 0.9, 0.8),   # blanco roto
	TrashType.PLASTIC:    Color(0.3, 0.6, 0.9),   # azul
}

# Formas placeholder por tipo
const TYPE_SHAPES = {
	TrashType.CAN:        "cylinder",
	TrashType.COFFEE_CUP: "cylinder",
	TrashType.PAPER:      "box",
	TrashType.PLASTIC:    "box",
}

func _ready() -> void:
	add_to_group("TrashItem")
	mass = 0.3
	physics_material_override = PhysicsMaterial.new()
	physics_material_override.bounce = 0.0
	physics_material_override.friction = 1.0
	linear_damp = 2.0
	angular_damp = 3.0
	_apply_visual()

func _apply_visual() -> void:
	if not mesh:
		return

	var mat = StandardMaterial3D.new()
	mat.albedo_color = TYPE_COLORS[trash_type]
	mesh.material_override = mat

	# Reemplazar el mesh según tipo
	match trash_type:
		TrashType.CAN, TrashType.COFFEE_CUP:
			var m = CylinderMesh.new()
			m.top_radius    = 0.04 if trash_type == TrashType.CAN else 0.035
			m.bottom_radius = 0.04 if trash_type == TrashType.CAN else 0.035
			m.height        = 0.15 if trash_type == TrashType.CAN else 0.10
			mesh.mesh = m
		TrashType.PAPER:
			var m = BoxMesh.new()
			m.size = Vector3(0.20, 0.02, 0.25)
			mesh.mesh = m
		TrashType.PLASTIC:
			var m = BoxMesh.new()
			m.size = Vector3(0.12, 0.05, 0.08)
			mesh.mesh = m
	
	# Actualizar collision shape
	var col = get_node_or_null("CollisionShape3D")
	if col:
		match trash_type:
			TrashType.CAN, TrashType.COFFEE_CUP:
				var s = CylinderShape3D.new()
				s.radius = 0.04 if trash_type == TrashType.CAN else 0.035
				s.height = 0.15 if trash_type == TrashType.CAN else 0.10
				col.shape = s
			TrashType.PAPER, TrashType.PLASTIC:
				var s = BoxShape3D.new()
				s.size = Vector3(0.20, 0.1	, 0.25) if trash_type == TrashType.PAPER else Vector3(0.12, 0.05, 0.08)
				col.shape = s

# Llamado por la bolsa al recogerlo
func collect() -> void:
	queue_free()
