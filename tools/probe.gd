extends SceneTree

const GRASS := Vector2i(0, 3)
const DIRT := Vector2i(0, 1)
const WATER := Vector2i(4, 10)


func _init() -> void:
	var root := Node2D.new()
	root.name = "Level1"
	var ts := TileSet.new()
	var src := TileSetAtlasSource.new()
	src.texture = load("res://assets/sprites/world_tileset.png")
	src.texture_region_size = Vector2i(16, 16)
	ts.add_source(src, 0)
	var level := TileMap.new()
	level.name = "Ground"
	level.tile_set = ts
	root.add_child(level)
	level.owner = root
	level.add_layer(0)
	level.set_cell(0, Vector2i(0, 0), 0, DIRT, 0)
	level.set_cell(0, Vector2i(1, 0), 0, GRASS, 0)
	level.set_cell(0, Vector2i(2, 0), 0, GRASS, 0)

	var scene := PackedScene.new()
	var err := scene.pack(root)
	if err != OK:
		push_error("pack err %d" % err)
		quit(1)
	var err2 := ResourceSaver.save(scene, "res://scenes/_probe.tscn")
	if err2 != OK:
		push_error("save err %d" % err2)
		quit(1)
	print("PROBE_SAVED")
	quit(0)
