extends TextureRect

func _ready():
	set_anchors_preset(Control.PRESET_CENTER)  # Centrar el control

func _draw():
	var center = size / 2
	draw_circle(center, 3, Color.WHITE)  # Dibuja un círculo blanco en el centro
