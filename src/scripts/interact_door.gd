extends Interactable

var isOpen = false
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var audio = $AudioStreamPlayer3D



func action_use():
	if isOpen:
		animation_player.play_backwards("openClose")
		audio.stream = preload("res://sounds/door_opening.wav")
		audio.play()
		isOpen = false
	elif !isOpen:
		animation_player.play("openClose")
		audio.stream = preload("res://sounds/door_closing.wav")
		audio.play()
		isOpen = true
