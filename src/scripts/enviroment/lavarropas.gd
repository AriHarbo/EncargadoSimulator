# lavarropas.gd
extends StaticBody3D

# Lavarropas: la InteractArea GRANDE sirve para cargar toallas sucias y
# sacar las limpias de a UNA con E. El lavado arranca SOLO desde el botón
# (lavarropas_boton.gd), que llama a start_wash().
# Las toallas limpias quedan dentro del tambor; no van al inventario solas.
const DIRTY_TOWEL_SCENE := preload("res://src/scenes/props/dirty_towel.tscn")
const CLEAN_TOWEL_SCENE := preload("res://src/scenes/props/clean_towel.tscn")
const MAX_CAPACITY := 4

@export var wash_time_seconds: float = 5.0

@onready var drum_anchor: Node3D = $DrumAnchor

var stored_dirty_quantity: int = 0
var stored_clean_quantity: int = 0
var washing: bool = false
var wash_timer: float = 0.0

var drum_nodes := { "dirty": null, "clean": null }

func _ready() -> void:
	add_to_group("Interactable")

func is_dirty_full() -> bool:
	return stored_dirty_quantity >= MAX_CAPACITY

func _holding_dirty_towel(player) -> bool:
	return player.equipped_item != null and player.equipped_item.is_in_group("dirty_towels")

func get_interact_hint(player) -> String:
	if washing:
		return "[Lavando... %ds]" % int(ceil(wash_timer))

	var holding := _holding_dirty_towel(player)
	if holding and is_dirty_full():
		return "[Lavarropas lleno (%d/%d)]" % [stored_dirty_quantity, MAX_CAPACITY]
	elif holding:
		return "[E] Meter toalla sucia (%d/%d)" % [stored_dirty_quantity, MAX_CAPACITY]
	elif stored_clean_quantity > 0:
		return "[E] Agarrar toalla limpia (%d)" % stored_clean_quantity
	return ""

func action_use() -> void:
	var player = get_tree().get_first_node_in_group("player")
	if not player:
		return
	if washing:
		return

	var holding := _holding_dirty_towel(player)
	if holding and not is_dirty_full():
		_deposit_one(player)
	elif not holding and stored_clean_quantity > 0:
		_take_clean_one(player)

func _process(delta: float) -> void:
	if not washing:
		return
	wash_timer -= delta
	if wash_timer <= 0.0:
		_finish_wash()

func start_wash() -> void:
	if washing or stored_dirty_quantity <= 0:
		return
	washing = true
	wash_timer = wash_time_seconds
	_refresh_visual()

func _deposit_one(player) -> void:
	var item = player.equipped_item
	var qty: int = item.get("quantity")

	stored_dirty_quantity += 1
	_refresh_visual()

	if qty > 1:
		item.quantity = qty - 1
		player.hotbar.refresh_slots()
	else:
		player.discard_equipped_item()

	player.show_message("Metiste una toalla sucia (%d/%d)" % [stored_dirty_quantity, MAX_CAPACITY])

func _take_clean_one(player) -> void:
	var towel: RigidBody3D = CLEAN_TOWEL_SCENE.instantiate()
	towel.freeze = true
	towel.visible = false
	get_tree().current_scene.add_child(towel)
	if not player.give_item(towel, "clean_towel"):
		towel.queue_free()
		player.show_message("No podes cargar más toallas")
		return

	stored_clean_quantity -= 1
	_refresh_visual()

func _finish_wash() -> void:
	washing = false
	stored_clean_quantity += stored_dirty_quantity
	stored_dirty_quantity = 0
	_refresh_visual()

func _refresh_visual() -> void:
	if washing:
		_drum_clear()
		return
	_sync_drum_node("dirty", stored_dirty_quantity, 0.0)
	_sync_drum_node("clean", stored_clean_quantity, stored_dirty_quantity * 0.06)

func _drum_clear() -> void:
	for key in drum_nodes:
		if drum_nodes[key]:
			drum_nodes[key].queue_free()
			drum_nodes[key] = null

func _sync_drum_node(kind: String, qty: int, offset_y: float) -> void:
	var node = drum_nodes[kind]
	if qty <= 0:
		if node:
			node.queue_free()
			drum_nodes[kind] = null
		return

	if node == null:
		var scene: PackedScene = DIRTY_TOWEL_SCENE if kind == "dirty" else CLEAN_TOWEL_SCENE
		node = scene.instantiate()
		node.freeze = true
		node.set_collision_layer_value(1, false)
		node.set_collision_mask_value(1, false)
		drum_anchor.add_child(node)
		node.transform = Transform3D.IDENTITY
		drum_nodes[kind] = node

	node.position.y = offset_y
	node.quantity = qty
