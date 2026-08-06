extends StaticBody3D

const BULB_SCENE = preload("res://src/scenes/props/bombilla.tscn")
const BURNT_BULB_SCENE = preload("res://src/scenes/props/bombilla_quemada.tscn")

const PROMPT_REMOVE = "Press A four times to take the burnt bulb off"
const PROMPT_INSTALL = "Press D four times to install the new bulb"

const TURNS_REQUIRED := 4
const TURN_MOVE := 0.0125
const INSTALL_START_Y := -0.05
const TURN_ROTATE_DEG := 90.0
const TURN_DURATION := 0.18

enum BulbState { EMPTY, BURNT, NEW }
enum MiniAction { NONE, REMOVE, INSTALL }

@onready var bulb_visual: Node3D = $BombillaVisual
@onready var burnt_bulb_visual: Node3D = $BombillaQuemadaVisual
@onready var light: OmniLight3D = $Luz
@onready var minigame_camera: Camera3D = $MinigameCamera
@onready var prompt: Label = $MinigameUI/Prompt

var state := BulbState.BURNT
var minigame_active := false
var minigame_action := MiniAction.NONE
var turn_count := 0
var _turn_tween: Tween

func _ready() -> void:
	add_to_group("Interactable")
	add_to_group("luz_sockets")
	_update_state()

func _input(event: InputEvent) -> void:
	if not minigame_active or turn_count >= TURNS_REQUIRED:
		return
	if event.is_action_pressed("move_left") and minigame_action == MiniAction.REMOVE:
		_advance_turn()
	elif event.is_action_pressed("move_right") and minigame_action == MiniAction.INSTALL:
		_advance_turn()

func action_use() -> void:
	var player = get_tree().get_first_node_in_group("player")
	if not player:
		return

	if minigame_active:
		return

	match state:
		BulbState.BURNT:
			_start_minigame(player, MiniAction.REMOVE)
		BulbState.NEW:
			_remove_bulb(player)
		BulbState.EMPTY:
			if not player.consume_item("bulb"):
				player.show_message("No tenés bombillas")
				return
			_start_minigame(player, MiniAction.INSTALL)

func _start_minigame(player: Node, action: MiniAction) -> void:
	minigame_action = action
	turn_count = 0
	minigame_active = true
	add_to_group("minigame_active")
	player.enter_minigame_camera(minigame_camera)
	if action == MiniAction.INSTALL:
		bulb_visual.transform = Transform3D.IDENTITY
		bulb_visual.position.y = INSTALL_START_Y
		bulb_visual.visible = true
	else:
		burnt_bulb_visual.transform = Transform3D.IDENTITY
	prompt.text = PROMPT_INSTALL if action == MiniAction.INSTALL else PROMPT_REMOVE
	prompt.visible = true

func _advance_turn() -> void:
	turn_count += 1
	_animate_turn()
	if turn_count >= TURNS_REQUIRED:
		var player = get_tree().get_first_node_in_group("player")
		if player:
			_finish_minigame(player)

func _animate_turn() -> void:
	var visual: Node3D
	var direction := 1.0
	match minigame_action:
		MiniAction.REMOVE:
			visual = burnt_bulb_visual
			direction = -1.0
		MiniAction.INSTALL:
			visual = bulb_visual
			direction = 1.0
	if visual == null:
		return

	var target_rotation_y := visual.rotation.y + deg_to_rad(TURN_ROTATE_DEG * direction)
	var target_position_y := visual.position.y + (TURN_MOVE * direction)

	if _turn_tween and _turn_tween.is_valid():
		_turn_tween.kill()

	_turn_tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_turn_tween.set_parallel(true)
	_turn_tween.tween_property(visual, "rotation:y", target_rotation_y, TURN_DURATION)
	_turn_tween.tween_property(visual, "position:y", target_position_y, TURN_DURATION)

func _finish_minigame(player: Node) -> void:
	prompt.visible = false
	player.exit_minigame_camera(func() -> void:
		_complete_action(player)
	)

func _complete_action(player: Node) -> void:
	minigame_active = false
	remove_from_group("minigame_active")
	match minigame_action:
		MiniAction.REMOVE:
			_remove_bulb(player)
		MiniAction.INSTALL:
			_install_bulb()
	minigame_action = MiniAction.NONE
	turn_count = 0

func _remove_bulb(player: Node) -> void:
	var is_burnt = state == BulbState.BURNT
	var scene = BURNT_BULB_SCENE if is_burnt else BULB_SCENE
	var item_type = "burnt_bulb" if is_burnt else "bulb"
	var previous = state
	state = BulbState.EMPTY
	_update_state()

	var bulb = scene.instantiate()
	get_tree().current_scene.add_child(bulb)
	bulb.global_transform.origin = global_transform.origin

	if not player.give_item(bulb, item_type):
		bulb.queue_free()
		state = previous
		_update_state()
		player.show_message("Inventario lleno")

func _install_bulb() -> void:
	state = BulbState.NEW
	_update_state()

func _update_state() -> void:
	bulb_visual.visible = state == BulbState.NEW
	burnt_bulb_visual.visible = state == BulbState.BURNT
	light.light_energy = 8.0 if state == BulbState.NEW else 0.0
