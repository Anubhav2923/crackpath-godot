extends Button


func _ready() -> void:
	# Ensure the button's pressed signal is connected once.
	if not pressed.is_connected(_on_next_level_pressed):
		pressed.connect(_on_next_level_pressed)


func _on_next_level_pressed() -> void:
	var controller := get_tree().get_first_node_in_group("levels")

	if controller == null:
		push_error("Next Level: No active level controller was found.")
		return

	if controller.has_method("load_next_level"):
		controller.call("load_next_level")
	else:
		push_error("Next Level: load_next_level() is missing.")
