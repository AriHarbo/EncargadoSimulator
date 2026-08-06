extends Area3D

func action_use() -> void:
	# El player llama esto al interactuar (E)
	var player = get_tree().get_first_node_in_group("player")
	if player and player.equipped_type == "mop":
		player.equipped_item.wash()
		print("Mopa lavada en el balde.")
