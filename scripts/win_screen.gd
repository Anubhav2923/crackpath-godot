extends Control


func _ready() -> void:
	# Ensure the win screen and its buttons process input even when the scene tree is paused.
	process_mode = Node.PROCESS_MODE_ALWAYS
	# Pause gameplay while the win screen is visible.
	get_tree().paused = true

	# Connect button signals if not already connected via the scene.
	var replay_button := get_node_or_null("Replay_button") as Button
	if replay_button and not replay_button.pressed.is_connected(_on_replay_button_pressed):
		replay_button.pressed.connect(_on_replay_button_pressed)

	var next_level_button := get_node_or_null("nextLevel") as Button
	if next_level_button and not next_level_button.pressed.is_connected(_on_next_level_pressed):
		next_level_button.pressed.connect(_on_next_level_pressed)

	var home_button := get_node_or_null("mainMenu") as Button
	if home_button and not home_button.pressed.is_connected(_on_main_menu_pressed):
		home_button.pressed.connect(_on_main_menu_pressed)


func _on_replay_button_pressed() -> void:
	# Unpause before reloading so the game runs normally upon restart.
	get_tree().paused = false
	var error := get_tree().reload_current_scene()
	if error != OK:
		push_error("Replay: Failed to reload current scene. Error code: " + str(error))


func _on_next_level_pressed() -> void:
	var controller := get_tree().get_first_node_in_group("levels")

	if controller == null:
		push_error("Next Level: No active level controller was found.")
		return

	if controller.has_method("load_next_level"):
		controller.call("load_next_level")
	else:
		push_error("Next Level: load_next_level() is missing.")


func _on_main_menu_pressed() -> void:
	# Unpause before navigating back to the main menu.
	get_tree().paused = false
	var error := get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
	if error != OK:
		push_error("Home: Failed to load main menu. Error code: " + str(error))
