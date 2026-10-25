extends CanvasLayer
## HUD for CRACKPATH.
## Attach to a CanvasLayer node named "HUD" (see main.tscn).
## Reads ALL values from the level controller - no separate counters.

var _moves_label: Label
var _coins_label: Label
var _undo_button: Button
var _restart_button: Button
var _status_label: Label

var _level: Node = null


func _ready() -> void:
	layer = 10
	_build_ui()
	# The level controller is ready at this point (siblings ready first),
	# so we can connect immediately.
	_level = get_tree().get_first_node_in_group("levels")
	if _level == null:
		push_error("HUD: no level controller found in group 'levels'.")
		return
	_level.state_changed.connect(_on_state_changed)
	_level.level_won.connect(_on_level_won)
	# Paint the initial values right away.
	_on_state_changed(_level.moves_used, _level.move_budget, _level.coins_collected, _level.coin_total)


func _build_ui() -> void:
	var root := Control.new()
	root.name = "Root"
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)

	var panel := PanelContainer.new()
	panel.name = "Panel"
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# Compact panel in the top-left corner, outside the play field.
	panel.position = Vector2(4, 4)
	root.add_child(panel)

	var box := VBoxContainer.new()
	box.name = "Box"
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_theme_constant_override("separation", 2)
	panel.add_child(box)

	var title := Label.new()
	title.name = "Title"
	title.text = "CRACKPATH"
	title.add_theme_font_size_override("font_size", 16)
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(title)

	_moves_label = Label.new()
	_moves_label.name = "MovesLabel"
	_moves_label.text = "Moves: 0 / 6"
	_moves_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(_moves_label)

	_coins_label = Label.new()
	_coins_label.name = "CoinsLabel"
	_coins_label.text = "Coins: 0 / 0"
	_coins_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(_coins_label)

	var goal := Label.new()
	goal.name = "GoalLabel"
	goal.text = "Reach the treasure!"
	goal.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(goal)

	var buttons := HBoxContainer.new()
	buttons.name = "Buttons"
	buttons.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(buttons)

	_undo_button = Button.new()
	_undo_button.name = "UndoButton"
	_undo_button.text = "Undo"
	# Undo is NOT implemented yet - keep it visibly disabled instead of faking it.
	_undo_button.disabled = true
	_undo_button.tooltip_text = "Undo is not implemented yet."
	buttons.add_child(_undo_button)

	_restart_button = Button.new()
	_restart_button.name = "RestartButton"
	_restart_button.text = "Restart"
	_restart_button.pressed.connect(_on_restart_pressed)
	buttons.add_child(_restart_button)

	_status_label = Label.new()
	_status_label.name = "StatusLabel"
	_status_label.text = ""
	_status_label.add_theme_font_size_override("font_size", 16)
	_status_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(_status_label)


func _on_state_changed(moves_used: int, move_budget: int, coins_collected: int, coin_total: int) -> void:
	var moves_remaining: int = maxi(move_budget - moves_used, 0)
	_moves_label.text = "Moves: %d / %d (left: %d)" % [moves_used, move_budget, moves_remaining]
	_coins_label.text = "Coins: %d / %d" % [coins_collected, coin_total]


func _on_level_won(moves_used: int, coins_collected: int) -> void:
	_status_label.text = "YOU WIN!"


func _on_restart_pressed() -> void:
	# Real restart: reload the current scene (resets player + level state).
	get_tree().reload_current_scene()
