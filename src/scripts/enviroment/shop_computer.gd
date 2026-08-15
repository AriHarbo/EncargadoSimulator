extends StaticBody3D

@export var shop_ui: CanvasLayer
@export var desktop_ui: CanvasLayer
@export var computer_camera: Camera3D
@export var order_spawn_point: Node3D 

var player: CharacterBody3D = null
var is_active := false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	if shop_ui:
		shop_ui.order_spawn_point = order_spawn_point

func action_use() -> void:
	if is_active:
		return
	player = get_tree().get_first_node_in_group("player")
	if player == null:
		push_warning("No encontré ningún nodo en el grupo 'player'")
		return

	is_active = true
	add_to_group("minigame_active")
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	set_process_unhandled_input(true)

	player.enter_minigame_camera(computer_camera, func():
		desktop_ui.visible = true
	)

func _unhandled_input(event: InputEvent) -> void:
	if not is_active:
		return
	if event.is_action_pressed("ui_cancel"):
		if shop_ui and shop_ui.esta_abierto():
			shop_ui.cerrar()
		else:
			_exit_computer()

func _exit_computer() -> void:
	desktop_ui.visible = false
	if shop_ui and shop_ui.esta_abierto():
		shop_ui.cerrar()
	remove_from_group("minigame_active")
	set_process_unhandled_input(false)
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

	player.exit_minigame_camera(func():
		is_active = false
		player = null
	)
