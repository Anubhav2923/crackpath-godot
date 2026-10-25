extends SceneTree
## Verify level_1.tscn tile layout.
## Run: godot_console.exe --headless --path <project> --script res://tools/verify_level1.gd

func _init() -> void:
	var scene: PackedScene = load("res://scenes/level_1.tscn") as PackedScene
	var node: Node = scene.instantiate()
	var tm: TileMap = node.get_node("Ground")
	if tm == null:
		push_error("NO Ground TileMap")
		quit(1)

	var cells := tm.get_used_cells(0)
	print("LEVEL1 cells=%d" % cells.size())

	# Build a readable grid map of atlas coords.
	var grid := {}
	for c in cells:
		var atlas := tm.get_cell_atlas_coords(0, c)
		var alt := tm.get_cell_alternative_tile(0, c)
		grid["%d,%d" % [c.x, c.y]] = "(%d,%d) a%d" % [atlas.x, atlas.y, alt]

	var COLS := 16
	var ROWS := 11
	var bad := 0
	for y in range(ROWS):
		var line := ""
		for x in range(COLS):
			var k := "%d,%d" % [x, y]
			if grid.has(k):
				line += " " + grid[k]
			else:
				line += "  ----  "
				bad += 1
		print(line)
	print("EMPTY=%d" % bad)

	# Check key cells.
	var checks := {
		"start (1,9)": Vector2i(1, 9),
		"goal (14,1)": Vector2i(14, 1),
		"water (11,4)": Vector2i(11, 4),
		"obstacle (5,2)": Vector2i(5, 2),
		"open (8,5)": Vector2i(8, 5),
	}
	for name in checks:
		var c := checks[name]
		var atlas := tm.get_cell_atlas_coords(0, c)
		var src := tm.get_cell_source_id(0, c)
		print("%s -> src=%d atlas=(%d,%d)" % [name, src, atlas.x, atlas.y])

	print("VERIFY_DONE")
	quit(0)