extends SceneTree
const COLS := 16
const ROWS := 11
const TILESIZE := 16
const GRASS := Vector2i(0, 3)
const DIRT := Vector2i(0, 1)
const WATER := Vector2i(4, 10)

func _init() -> void:
	var root := Node2D.new()
	root.name = "Level1"
	var ts := TileSet.new()
	var src := TileSetAtlasSource.new()
	src.texture = load("res://assets/sprites/world_tileset.png")
	src.texture_region_size = Vector2i(TILESIZE, TILESIZE)
	ts.add_source(src, 0)
	var level := TileMap.new()
	level.name = "Ground"
	level.tile_set = ts
	root.add_child(level)
	level.owner = root
	level.add_layer(0)

	for y in range(ROWS):
		for x in range(COLS):
			var cell := Vector2i(x, y)
			if x == 0 or x == COLS - 1 or y == 0 or y == ROWS - 1:
				level.set_cell(0, cell, 0, DIRT, 0)
				continue
			if x >= 10 and x <= 12 and y >= 3 and y <= 6:
				level.set_cell(0, cell, 0, WATER, 0)
				continue
			if _blocked(cell):
				level.set_cell(0, cell, 0, DIRT, 0)
				continue
			if cell == Vector2i(14, 1):
				level.set_cell(0, cell, 0, Vector2i(7, 5), 0)
				continue
			level.set_cell(0, cell, 0, GRASS, 0)

	var scene := PackedScene.new()
	var err := scene.pack(root)
	if err != OK:
		push_error("pack err %d" % err)
		quit(1)
	ResourceSaver.save(scene, "res://scenes/level_1.tscn")
	print("LEVEL1_SAVED")
	quit(0)

func _blocked(c: Vector2i) -> bool:
	var b := [
		Vector2i(4,1),Vector2i(9,1),Vector2i(12,1),Vector2i(2,2),Vector2i(2,3),
		Vector2i(5,2),Vector2i(5,3),Vector2i(10,2),Vector2i(6,4),Vector2i(7,4),
		Vector2i(3,6),Vector2i(4,6),Vector2i(5,6),Vector2i(8,7),Vector2i(8,8),
		Vector2i(11,7),Vector2i(12,7)
	]
	return b.has(c)
