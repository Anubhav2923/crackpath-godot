extends Area2D

@export var win_screen_scene: PackedScene

var _win_screen_shown: bool = false


func _ready() -> void:
	# Connect only if the signal isn't already connected.
	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node2D) -> void:
	print(">>> Level_End: body_entered fired! Body = ", body.name)

	if _win_screen_shown:
		print(">>> Level_End: win screen already shown, ignoring.")
		return

	if not body.is_in_group("player"):
		print(">>> Level_End: body '", body.name, "' is NOT in 'player' group. Groups = ", body.get_groups())
		return

	print(">>> Level_End: Player confirmed! Searching for level controller...")
	var controller := get_tree().get_first_node_in_group("levels")

	if controller == null:
		push_error("Level_End: No level controller was found.")
		return

	if not controller.has_method("report_goal_reached"):
		push_error("Level_End: The controller cannot report a win.")
		return

	if win_screen_scene == null:
		push_error("Level_End: win_screen_scene is null — assign it in the Inspector.")
		return

	print(">>> Level_End: All checks passed — showing win screen!")
	_win_screen_shown = true
	set_deferred("monitoring", false)

	# Record the win before displaying the overlay.
	controller.call("report_goal_reached")

	# Instantiate the win screen overlay.
	var overlay := win_screen_scene.instantiate() as Control

	if overlay == null:
		push_error("Level_End: The Win Screen root must be a Control node.")
		_win_screen_shown = false
		set_deferred("monitoring", true)
		return

	# Add to a CanvasLayer so the overlay renders in screen space,
	# not world space. Without this, Camera2D zoom makes it invisible.
	var canvas := CanvasLayer.new()
	canvas.layer = 10  # Render on top of everything else.
	get_tree().current_scene.add_child(canvas)

	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	canvas.add_child(overlay)
	print(">>> Level_End: Win screen successfully added to scene!")
