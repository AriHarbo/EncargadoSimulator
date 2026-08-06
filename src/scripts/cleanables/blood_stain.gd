extends Area3D

var hits_required := 3  # cuántos pasadas de mopa para limpiar
var current_hits := 0
@onready var particles = $GPUParticles3D

func _ready() -> void:
	# Crear material único para cada instancia
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.54, 0.0, 0.0, 1.0)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	$MeshInstance3D.set_surface_override_material(0, mat)

func hit() -> void:
	current_hits += 1
	var ratio = 1.0 - (float(current_hits) / float(hits_required))
	
	# Achica la mancha visualmente con cada pasada
	scale = Vector3(ratio + 0.1, 1.0, ratio + 0.1)
	particles.restart()
	particles.emitting = true
	# Actualizar transparencia
	var mat = $MeshInstance3D.get_surface_override_material(0)
	if mat == null:
		mat = StandardMaterial3D.new()
		$MeshInstance3D.set_surface_override_material(0, mat)
	mat.albedo_color = Color(0.54, 0.0, 0.0, ratio)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	
	if current_hits >= hits_required:
		queue_free()
