extends Node2D
## Level controller for Level 1.
## OWNS this level's move budget and coin target.
## Attach to the Level_1 root node (the existing root of scenes/level_1.tscn).

signal state_changed(moves_used: int, move_budget: int, coins_collected: int, coin_total: int)
signal level_won(moves_used: int, coins_collected: int)

@export_range(1, 999, 1) var move_budget: int = 6
@export_file("*.tscn") var next_level_path: String = ""

var coin_total: int = 0
var coins_collected: int = 0
var moves_used: int = 0

var _player: Node = null
var _won: bool = false


func _ready() -> void:
	add_to_group("levels")

	# 1. Count ONLY the coins that belong to this level's own scene tree.
	coin_total = _count_own_coins()
	if coin_total == 0:
		push_warning("Level_1: no coins found in the coins group inside this level.")

	# 2. Find the player (it lives in main.tscn, next to this level).
	_player = get_tree().get_first_node_in_group("player")
	if _player == null:
		push_error("Level_1: no node in group 'player' found.")
		return

	# 3. Configure the player BEFORE it may accept input.
	if _player.has_method("configure_for_level"):
		_player.configure_for_level(move_budget)
	else:
		push_error("Level_1: player has no configure_for_level() method.")

	# 4. Follow the player's runtime counters (single source of truth = player).
	if not _player.moves_changed.is_connected(_on_player_moves_changed):
		_player.moves_changed.connect(_on_player_moves_changed)
	if not _player.coins_changed.is_connected(_on_player_coins_changed):
		_player.coins_changed.connect(_on_player_coins_changed)

	print("LEVEL READY: budget=%d coins=%d" % [move_budget, coin_total])
	_emit_state()


func _count_own_coins() -> int:
	# Count nodes in the "coins" group that are descendants of THIS level,
	# so coins from other loaded levels are never included.
	var count := 0
	for coin in get_tree().get_nodes_in_group("coins"):
		if is_ancestor_of(coin):
			count += 1
	return count


func _on_player_moves_changed(used: int) -> void:
	moves_used = used
	_emit_state()
	_check_win()


func _on_player_coins_changed(collected: int) -> void:
	coins_collected = collected
	_emit_state()


func _check_win() -> void:
	# Win = player reached the treasure (Level_End area) with moves remaining.
	# The treasure scene handles the actual body_entered detection.
	pass


## Called by the treasure (Level_End) when the player reaches the goal.
func report_goal_reached() -> void:
	if _won:
		return
	_won = true
	level_won.emit(moves_used, coins_collected)
	state_changed.emit(moves_used, move_budget, coins_collected, coin_total)


func _emit_state() -> void:
	state_changed.emit(moves_used, move_budget, coins_collected, coin_total)


func load_next_level() -> void:
	if not _won:
		push_warning("Cannot advance: the current level has not been won.")
		return

	if next_level_path.is_empty():
		push_warning("Next level path is not set; returning to main menu.")
		get_tree().paused = false
		get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
		return

	# Unpause the game before loading the next scene.
	get_tree().paused = false

	var error := get_tree().change_scene_to_file(next_level_path)

	if error != OK:
		push_error(
			"Failed to load the next level. Error code: " + str(error)
		)
