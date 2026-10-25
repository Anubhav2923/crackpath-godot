
extends CharacterBody2D

signal moves_changed(moves_used: int)
signal coins_changed(total_coins: int)
signal slide_finished(moves_used: int, total_coins: int)

@export var tile_size: float = 16.0
@export var slide_speed: float = 180.0
@export var swipe_threshold: float = 30.0

var is_sliding: bool = false
var moving_to_cell: bool = false
var slide_direction: Vector2 = Vector2.ZERO
var target_position: Vector2 = Vector2.ZERO

var moves_used: int = 0
var coins_collected: int = 0
var counted_this_swipe: bool = false

var touch_start: Vector2 = Vector2.ZERO
var touch_active: bool = false
var mouse_start: Vector2 = Vector2.ZERO
var mouse_active: bool = false


func _ready() -> void:
	add_to_group("player")


func _unhandled_input(event: InputEvent) -> void:
	if is_sliding or moving_to_cell:
		return

	# Keyboard controls for desktop testing.
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

	# Touchscreen swipe controls.
	elif event is InputEventScreenTouch:
		if event.pressed:
			touch_start = event.position
			touch_active = true
		elif touch_active:
			touch_active = false
			_handle_swipe(event.position - touch_start)

	# Mouse dragging makes testing easier on Windows.
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
	if is_sliding or moving_to_cell:
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

	# Test the entire next cell before moving.
	# Walls, rocks, crates and water must have physics shapes.
	if test_move(global_transform, motion, null, 0.01):
		_finish_slide()
		return

	target_position = global_position + motion
	moving_to_cell = true

	# One swipe is one move, regardless of how many cells it crosses.
	if not counted_this_swipe:
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


func collect_coin(value: int = 1) -> void:
	coins_collected += value
	coins_changed.emit(coins_collected)

	print("Coin collected! Total: ", coins_collected)
