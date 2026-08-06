extends ProgressBar

func _ready() -> void:
	visible = false
	min_value = 0.0
	max_value = 1.0
	value = 0.0

func show_bar() -> void:
	visible = true

func hide_bar() -> void:
	visible = false
	value = 0.0

func update_fill(ratio: float) -> void:
	value = ratio
