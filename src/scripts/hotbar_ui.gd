extends CanvasLayer

@onready var slots = $HBoxContainer.get_children()

# Cada entrada: { "node": RigidBody3D, "type": String } o null
var hotbar_items := [null, null, null, null, null]
var selected_slot := 0

signal slot_changed(item_node, item_type)

func _ready() -> void:
	update_visual()

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_slot_1"):   select_slot(0)
	elif event.is_action_pressed("ui_slot_2"): select_slot(1)
	elif event.is_action_pressed("ui_slot_3"): select_slot(2)
	elif event.is_action_pressed("ui_slot_4"): select_slot(3)

func select_slot(index: int) -> void:
	if index < 0 or index >= hotbar_items.size():
		return
	selected_slot = index
	update_visual()

	var player = get_tree().get_first_node_in_group("player")
	if player:
		var entry = hotbar_items[selected_slot]
		if entry:
			player.equip_item(entry["node"], entry["type"])
		else:
			player.equip_item(null, "")

	var entry = hotbar_items[selected_slot]
	slot_changed.emit(
		entry["node"] if entry else null,
		entry["type"] if entry else ""
	)

func get_free_slot() -> int:
	for i in range(hotbar_items.size()):
		if hotbar_items[i] == null:
			return i
	return -1

func add_item_to_slot(index: int, node: RigidBody3D, type: String) -> void:
	hotbar_items[index] = { "node": node, "type": type }
	refresh_slots()

func remove_item_from_slot(index: int) -> void:
	hotbar_items[index] = null
	refresh_slots()

func update_visual() -> void:
	for i in range(slots.size()):
		if i == selected_slot:
			slots[i].modulate = Color(1.2, 0.9, 0.3)
			slots[i].scale = Vector2(1.02, 1.02)
		else:
			slots[i].modulate = Color(1, 1, 1)
			slots[i].scale = Vector2(1, 1)

func refresh_slots() -> void:
	for i in range(slots.size()):
		var slot = slots[i]
		var icon = slot.get_node_or_null("Icon")

		# Limpiar labels previos
		for child in slot.get_children():
			if child != icon and child is Label:
				child.queue_free()

		var entry = hotbar_items[i]
		if entry != null:
			var label = Label.new()
			label.text = entry["type"].capitalize()   # "Broom" / "Mop"
			label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			label.custom_minimum_size = Vector2(64, 64)
			slot.add_child(label)
			if icon: icon.visible = false
		else:
			if icon: icon.visible = false

func has_item(tool_node: RigidBody3D) -> bool:
	for entry in hotbar_items:
		if entry != null and entry["node"] == tool_node:
			return true
	return false
