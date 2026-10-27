extends Control


func _on_undo_pressed() -> void:
	var player := get_tree().get_first_node_in_group("player")

	if player == null:
		push_warning("Undo: no player found in the player group.")
		return

	if player.has_method("undo_last_move"):
		player.call("undo_last_move")
	else:
		push_warning("Undo: player does not implement undo_last_move().")
