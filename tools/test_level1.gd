extends SceneTree
## Headless verification for the level-specific move budget + coin HUD task.
## Run: godot_console.exe --headless --path <project> --script res://tools/test_level1.gd

var _frame := 0
var _phase := 0
var _game: Node = null
var _player: Node = null
var _level: Node = null
var _hud: CanvasLayer = null
var _failures := 0
var _coins_before := 0
var _pos_before: Vector2 = Vector2.ZERO
var _moves_before := 0
var _dir_index := 0
var _moved_count := 0
var _issued := false
var _wait_frames := 0
var _directions: Array = [Vector2.DOWN, Vector2.RIGHT, Vector2.UP, Vector2.LEFT]


func _initialize() -> void:
	pass


func _process(delta: float) -> bool:
	_frame += 1
	if _frame == 1:
		var main_scene: PackedScene = load("res://scenes/main.tscn")
		_game = main_scene.instantiate()
		root.add_child(_game)
		_player = _game.get_tree().get_first_node_in_group("player")
		_level = _game.get_tree().get_first_node_in_group("levels")
		_hud = _game.get_node_or_null("HUD")
	match _phase:
		0:
			# Let _ready + a few physics frames run.
			if _frame >= 5:
				_check_initial_state()
				_phase = 1
		1:
			# Try all four directions in sequence, waiting for each slide to
			# fully finish before issuing the next input. For each input: if the
			# player moved, exactly 1 move must be consumed; if blocked, 0 moves.
			if not _issued:
				if _dir_index >= _directions.size():
					_check("at least one direction caused movement", _moved_count >= 1)
					_check("moves never exceed level budget", _player.moves_used <= _level.move_budget)
					_finish()
					return true
				_coins_before = _player.coins_collected
				_pos_before = _player.global_position
				_moves_before = _player.moves_used
				_player._start_slide(_directions[_dir_index])
				print("Input %s" % str(_directions[_dir_index]))
				_issued = true
				_wait_frames = 0
			else:
				_wait_frames += 1
				# A slide ends when is_sliding turns false; 600 frames is the
				# safety timeout (longest possible slide is well under that).
				if not _player.is_sliding or _wait_frames > 600:
					_check_slide(_directions[_dir_index])
					_dir_index += 1
					_issued = false
					if _dir_index >= _directions.size():
						_check("at least one direction caused movement", _moved_count >= 1)
						_check("moves never exceed level budget", _player.moves_used <= _level.move_budget)
						_dir_index = 0
						_phase = 2
		2:
			# Keep sliding until the budget is exhausted, then confirm the
			# player cannot exceed it and further input is refused.
			if not _issued:
				_moves_before = _player.moves_used
				_pos_before = _player.global_position
				_player._start_slide(_directions[_dir_index])
				_dir_index = (_dir_index + 1) % _directions.size()
				_issued = true
				_wait_frames = 0
			else:
				_wait_frames += 1
				if not _player.is_sliding or _wait_frames > 600:
					_issued = false
					_check("budget invariant holds after extra input", _player.moves_used <= _level.move_budget)
					if _player.moves_used >= _level.move_budget:
						_phase = 3
					elif _wait_frames > 600:
						# Nothing more can happen; stop early.
						_phase = 3
		3:
			# Budget exhausted: input must be refused without moving or counting.
			if not _issued:
				_moves_before = _player.moves_used
				_pos_before = _player.global_position
				_player._start_slide(Vector2.RIGHT)
				_issued = true
				_wait_frames = 0
			else:
				_wait_frames += 1
				if not _player.is_sliding or _wait_frames > 60:
					if _moves_before >= _level.move_budget:
						_check("input refused at 0 moves remaining (no move consumed)",
								_player.moves_used == _moves_before)
						_check("player did not move when refused",
								_player.global_position.distance_to(_pos_before) < 0.5)
					_check("final moves within level budget",
							_player.moves_used <= _level.move_budget)
					print("Final: moves=%d/%d coins=%d/%d" % [
							_player.moves_used, _level.move_budget,
							_player.coins_collected, _level.coin_total])
					_finish()
					return true
	return false


func _check_initial_state() -> void:
	if _level == null:
		_fail("level controller not found in group 'levels'")
		return
	if _player == null:
		_fail("player not found in group 'player'")
		return
	_check("moves_used starts at 0", _player.moves_used == 0)
	_check("move_budget == 6 (from level)", _player.move_budget == 6)
	_check("level.move_budget == 6", _level.move_budget == 6)
	_check("player.is_configured == true", _player.is_configured == true)

	# Real coin count from the scene file (instances of coin.tscn).
	var real_coins := _count_scene_coins(_game.get_node("Level_1"))
	_check("coin_total (%d) matches scene coin instances (%d)" % [_level.coin_total, real_coins],
			_level.coin_total == real_coins)
	_check("player.coins_collected starts at 0", _player.coins_collected == 0)

	if _hud == null:
		_fail("HUD node missing in main.tscn")
		return
	var moves_label: Label = _hud.get_node_or_null("Root/Panel/Box/MovesLabel")
	var coins_label: Label = _hud.get_node_or_null("Root/Panel/Box/CoinsLabel")
	var undo_button: Button = _hud.get_node_or_null("Root/Panel/Box/Buttons/UndoButton")
	if moves_label == null or coins_label == null or undo_button == null:
		_fail("HUD children missing")
		return
	_check("HUD moves text shows 0 / 6", moves_label.text.contains("0 / 6"))
	_check("HUD coins text shows total %d" % real_coins,
			coins_label.text.contains("0 / %d" % real_coins))
	_check("Undo button is disabled (not faked)", undo_button.disabled == true)
	print("HUD moves: %s | coins: %s" % [moves_label.text, coins_label.text])


func _check_slide(dir: Vector2) -> void:
	_check("player stopped sliding after %s" % str(dir), _player.is_sliding == false)
	var moved: bool = _player.global_position.distance_to(_pos_before) > 0.5
	if moved:
		_moved_count += 1
		_check("valid slide %s consumed exactly 1 move" % str(dir),
				_player.moves_used == _moves_before + 1)
		# Coins collected along the path update exactly once each.
		_check("coin counter never decreases", _player.coins_collected >= _coins_before)
		var moves_label: Label = _hud.get_node_or_null("Root/Panel/Box/MovesLabel")
		if moves_label:
			_check("HUD shows %d moves" % _player.moves_used,
					moves_label.text.contains("%d / 6" % _player.moves_used))
	else:
		_check("blocked slide %s consumed 0 moves" % str(dir),
				_player.moves_used == _moves_before)
	print("Slide %s: moved=%s moves=%d coins=%d" % [str(dir), moved, _player.moves_used, _player.coins_collected])


func _count_scene_coins(node: Node) -> int:
	var count := 0
	if node.is_in_group("coins"):
		count += 1
	for child in node.get_children():
		count += _count_scene_coins(child)
	return count


func _check(what: String, ok: bool) -> void:
	if ok:
		print("PASS: " + what)
	else:
		_fail(what)


func _fail(what: String) -> void:
	_failures += 1
	print("FAIL: " + what)


func _finish() -> void:
	if _failures == 0:
		print("ALL_CHECKS_PASSED")
		quit(0)
	else:
		print("CHECKS_FAILED: %d" % _failures)
		quit(1)
