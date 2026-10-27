
extends CharacterBody2D

signal moves_changed(moves_used: int)
signal coins_changed(total_coins: int)
signal slide_finished(moves_used: int, total_coins: int)

@export var tile_size: float = 16.0
@export var slide_speed: float = 180.0
@export var swipe_threshold: float = 30.0

# The move budget is NOT owned by the player.
# It is supplied by the current level via configure_for_level().
var move_budget: int = 0

# Input stays locked until the level controller has configured this player.
var is_configured: bool = false

var is_sliding: bool = false
var moving_to_cell: bool = false
var slide_direction: Vector2 = Vector2.ZERO
var target_position: Vector2 = Vector2.ZERO

var moves_used: int = 0
var coins_collected: int = 0
var counted_this_swipe: bool = false


# One snapshot is saved for each valid state
var undo_history : Array[Dictionary]= []

var collected_coin_nodes : Array[Node] = []

var touch_start: Vector2 = Vector2.ZERO
var touch_active: bool = false
var mouse_start: Vector2 = Vector2.ZERO
var mouse_active: bool = false


func _ready() -> void:
	add_to_group("player")


## Called by the level controller at level start.
## The level passes its own budget; the player only stores and enforces it.

func configure_for_level(budget: int) -> void:
	move_budget = budget
	moves_used = 0
	coins_collected = 0

	undo_history.clear()
	collected_coin_nodes.clear()

	is_sliding = false
	moving_to_cell = false
	slide_direction = Vector2.ZERO
	counted_this_swipe = false
	target_position = global_position
	velocity = Vector2.ZERO

	is_configured = true

	moves_changed.emit(moves_used)
	coins_changed.emit(coins_collected)

func _input(event: InputEvent) -> void:
	if not is_configured or is_sliding or moving_to_cell:
		return

	# ── Keyboard (desktop / editor testing) ───────────────────────────────────
	if event is InputEventKey:
		if not event.pressed or event.echo:
			return
		if event.keycode == KEY_UP or event.keycode == KEY_W:
			_start_slide(Vector2.UP)
		elif event.keycode == KEY_DOWN or event.keycode == KEY_S:
			_start_slide(Vector2.DOWN)
		elif event.keycode == KEY_LEFT or event.keycode == KEY_A:
			_start_slide(Vector2.LEFT)
		elif event.keycode == KEY_RIGHT or event.keycode == KEY_D:
			_start_slide(Vector2.RIGHT)

	# ── Touch: finger press → record start ───────────────────────────────────
	elif event is InputEventScreenTouch:
		if event.pressed:
			touch_start = event.position
			touch_active = true
		elif touch_active:
			# Finger lifted — compute swipe from start to current position.
			touch_active = false
			_handle_swipe(event.position - touch_start)

	# ── Touch: finger drag → keep updating end position ──────────────────────
	# This ensures that even if the touch-up position is imprecise we still
	# have the last known drag position to measure the swipe against.
	elif event is InputEventScreenDrag:
		if touch_active:
			# Check threshold already — fire swipe as soon as it's far enough.
			var delta: Vector2 = event.position - touch_start
			if delta.length() >= swipe_threshold:
				touch_active = false
				_handle_swipe(delta)

	# ── Mouse drag (editor / desktop testing) ────────────────────────────────
	elif event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				mouse_start = event.position
				mouse_active = true
			elif mouse_active:
				mouse_active = false
				_handle_swipe(event.position - mouse_start)


func _handle_swipe(swipe: Vector2) -> void:
	if swipe.length() < swipe_threshold:
		return

	if absf(swipe.x) > absf(swipe.y):
		if swipe.x > 0.0:
			_start_slide(Vector2.RIGHT)
		else:
			_start_slide(Vector2.LEFT)
	else:
		if swipe.y > 0.0:
			_start_slide(Vector2.DOWN)
		else:
			_start_slide(Vector2.UP)


func _start_slide(direction: Vector2) -> void:
	if not is_configured or is_sliding or moving_to_cell:
		return

	if moves_used >= move_budget :
		print("No moves remaining")
		return 
		
	slide_direction = direction
	is_sliding = true
	counted_this_swipe = false


func _physics_process(delta: float) -> void:
	if moving_to_cell:
		_move_toward_cell(delta)
	elif is_sliding:
		_begin_next_cell()



func _begin_next_cell() -> void:
	var motion: Vector2 = slide_direction * tile_size

	# A blocked slide must not consume a move or create history.
	if test_move(global_transform, motion, null, 0.01):
		_finish_slide()
		return

	target_position = global_position + motion
	moving_to_cell = true

	# Save state once per slide, not once per cell.
	if not counted_this_swipe:
		_save_undo_snapshot()

		counted_this_swipe = true
		moves_used += 1
		moves_changed.emit(moves_used)

func _move_toward_cell(delta: float) -> void:
	var remaining: Vector2 = target_position - global_position
	var max_distance: float = slide_speed * delta
	var movement: Vector2

	if remaining.length() <= max_distance:
		movement = remaining
	else:
		movement = remaining.normalized() * max_distance

	# Perform actual movement through the physics engine.
	var collision = move_and_collide(movement)

	if collision != null:
		moving_to_cell = false
		_finish_slide()
		return

	# Reached the next cell center.
	if global_position.distance_to(target_position) < 0.01:
		moving_to_cell = false


func _finish_slide() -> void:
	is_sliding = false
	moving_to_cell = false
	slide_direction = Vector2.ZERO

	slide_finished.emit(moves_used, coins_collected)


func collect_coin(value: int = 1, coin: Node = null) -> void:
	coins_collected += value

	if coin != null and not collected_coin_nodes.has(coin):
		collected_coin_nodes.append(coin)

	coins_changed.emit(coins_collected)
	print("Coin collected! Total: ", coins_collected)


func _save_undo_snapshot() -> void:
	var snapshot: Dictionary = {
		"position": global_position,
		"moves_used": moves_used,
		"coins_collected": coins_collected,
		"collected_coin_nodes": collected_coin_nodes.duplicate()
	}

	undo_history.append(snapshot)


func undo_last_move() -> void:
	if not is_configured:
		return

	# Never teleport the player while a slide is in progress.
	if is_sliding or moving_to_cell:
		print("Undo unavailable while the player is sliding.")
		return

	if undo_history.is_empty():
		print("Nothing to undo.")
		return

	var snapshot: Dictionary = undo_history.pop_back()
	var previous_coins: Array = snapshot["collected_coin_nodes"]

	# Restore coins collected during the slide being undone.
	for coin in collected_coin_nodes:
		if not is_instance_valid(coin):
			continue

		if not previous_coins.has(coin):
			if coin.has_method("restore_coin"):
				coin.call("restore_coin")

	# Restore the collection history.
	collected_coin_nodes.clear()

	for coin in previous_coins:
		if is_instance_valid(coin):
			collected_coin_nodes.append(coin)

	# Restore the player's previous state.
	global_position = snapshot["position"]
	target_position = global_position

	moves_used = int(snapshot["moves_used"])
	coins_collected = int(snapshot["coins_collected"])

	is_sliding = false
	moving_to_cell = false
	slide_direction = Vector2.ZERO
	counted_this_swipe = false
	velocity = Vector2.ZERO

	# Notify the level controller and any connected UI.
	moves_changed.emit(moves_used)
	coins_changed.emit(coins_collected)
	slide_finished.emit(moves_used, coins_collected)

	print("Move undone. Moves used: ", moves_used)
