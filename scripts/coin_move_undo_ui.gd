extends Control

@onready var coin_count_label = $Coin_UI/Label
@onready var current_move_label = $moves_used/current_move
@onready var total_moves_lable : Label = $moves_used/total_moves

var active_level : Node


func _ready() -> void:
	# Wait one frame so ALL nodes have finished their own _ready(),
	# including Level_1 which calls add_to_group("levels") inside _ready().
	await get_tree().process_frame
	_connect_to_level()


func _connect_to_level() -> void:
	active_level = get_tree().get_first_node_in_group("levels")

	if active_level == null:
		push_error("CoinMoveUI: No active level controller found.")
		return

	if not active_level.has_signal("state_changed"):
		push_error("CoinMoveUI: Level controller has no state_changed signal.")
		return

	if not active_level.state_changed.is_connected(_on_level_state_changed):
		active_level.state_changed.connect(_on_level_state_changed)

	# Refresh labels immediately with the current level state.
	_on_level_state_changed(
		active_level.moves_used,
		active_level.move_budget,
		active_level.coins_collected,
		active_level.coin_total
	)


func _on_level_state_changed(moves_used: int, move_budget: int, coins_collected: int, _coin_total: int) -> void:
	if current_move_label != null:
		current_move_label.text = str(moves_used)
	if total_moves_lable != null:
		total_moves_lable.text = str(move_budget)
	if coin_count_label != null:
		coin_count_label.text = str(coins_collected)
