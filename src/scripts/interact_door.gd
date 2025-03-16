extends Interactable

var isOpen = false
@onready var animation_player: AnimationPlayer = $AnimationPlayer

func action_use():
	if isOpen:
		animation_player.play_backwards("openClose")
		isOpen = false
	elif !isOpen:
		animation_player.play("openClose")
		isOpen = true
