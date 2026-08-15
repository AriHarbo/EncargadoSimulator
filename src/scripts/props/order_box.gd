extends RigidBody3D

const ITEM_SCENES := {
	"trash_bag": preload("res://src/scenes/tools/trash_bag.tscn"),
	"bulb": preload("res://src/scenes/props/bombilla.tscn"),  # TODO: confirmar path real
}

const OPEN_ANGLE_DEG := 100.0
const OPEN_DURATION := 0.4
const INTERIOR_SIZE := Vector3(0.46, 0.27, 0.36)  # ancho, alto, profundidad interior (ajustá si cambian las paredes)
const ITEM_MARGIN := 0.01

@onready var lid_left_pivot: Node3D = $LidLeftPivot
@onready var lid_right_pivot: Node3D = $LidRightPivot
@onready var contents_node: Node3D = $Contents

var item_type: String = ""
var is_open: bool = false
var is_held: bool = false
var _tween: Tween = null

func _ready() -> void:
	add_to_group("order_box")
	_set_contents_visible(false)

func setup(type: String, amount: int) -> void:
	item_type = type
	for i in range(amount):
		_spawn_item(i, amount)

func get_contents_node() -> Node3D:
	return contents_node

func get_quantity() -> int:
	return contents_node.get_child_count()

func is_empty() -> bool:
	return get_quantity() <= 0

# ─── ABRIR / CERRAR (solo si NO está en mano) ─────────────────────────────

func toggle_open() -> void:
	if is_held:
		return
	if is_open:
		close_box()
	else:
		open_box()

func open_box() -> void:
	if is_held or is_open:
		return
	is_open = true
	_set_contents_visible(true)
	_animate_lids(-OPEN_ANGLE_DEG)

func close_box() -> void:
	if not is_open:
		return
	is_open = false
	_set_contents_visible(false)
	_animate_lids(0.0)

func _animate_lids(target_deg: float) -> void:
	if _tween and _tween.is_valid():
		_tween.kill()
	_tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_tween.tween_property(lid_left_pivot, "rotation_degrees:z", -target_deg, OPEN_DURATION)
	_tween.tween_property(lid_right_pivot, "rotation_degrees:z", target_deg, OPEN_DURATION)
	
func _set_contents_visible(value: bool) -> void:
	for child in contents_node.get_children():
		child.visible = value
		child.set_collision_layer_value(1, value)
		child.set_collision_mask_value(1, value)

# ─── LEVANTAR EN MANO ──────────────────────────────────────────────────────

func set_held(value: bool) -> void:
	if value and is_open:
		close_box()
	is_held = value

# ─── CONTENIDO ─────────────────────────────────────────────────────────────

func consume(amount: int) -> int:
	var taken := 0
	for child in contents_node.get_children():
		if taken >= amount:
			break
		contents_node.remove_child(child)	
		child.queue_free()
		taken += 1
	call_deferred("_update_label")
	return taken

func _spawn_item(index: int, total: int) -> void:
	if not ITEM_SCENES.has(item_type):
		push_warning("No hay escena registrada para item_type: %s" % item_type)
		return
	var item = ITEM_SCENES[item_type].instantiate()
	contents_node.add_child(item)
	item.freeze = true
	item.visible = false
	item.set_collision_layer_value(1, false)
	item.set_collision_mask_value(1, false)
	item.transform = Transform3D.IDENTITY

	var item_size = _get_item_size(item)
	item.position = _grid_position_3d(index, item_size)

func _get_item_size(item: Node3D) -> Vector3:
	for child in item.get_children():
		if child is VisualInstance3D:
			var aabb = child.get_aabb()
			return aabb.size
	return Vector3(0.1, 0.1, 0.1)  # fallback si no encuentra mesh

func _grid_position_3d(index: int, item_size: Vector3) -> Vector3:
	var step_x = item_size.x + ITEM_MARGIN
	var step_z = item_size.z + ITEM_MARGIN
	var step_y = item_size.y + ITEM_MARGIN

	var cols = max(1, int(INTERIOR_SIZE.x / step_x))
	var rows_per_layer = max(1, int(INTERIOR_SIZE.z / step_z))
	var per_layer = cols * rows_per_layer

	var layer = index / per_layer
	var index_in_layer = index % per_layer
	var col = index_in_layer % cols
	var row = index_in_layer / cols

	var x = (col - (cols - 1) * 0.5) * step_x
	var z = (row - (rows_per_layer - 1) * 0.5) * step_z
	var y = item_size.y * 0.5 + layer * step_y

	return Vector3(x, y, z)
