extends SceneTree
## Headless inspection tool: dumps the node hierarchy and every painted tile
## of the CRACKPATH scenes without opening the editor.
## Run: godot_console.exe --headless --path <project> --script res://tools/inspect_level.gd

var _indent := ""


func _init() -> void:
	_dump(load("res://scenes/level.tscn").instantiate())
	_dump(load("res://scenes/main.tscn").instantiate())
	print("INSPECT_DONE")
	quit(0)


func _dump(node: Node) -> void:
	var extra := ""
	if node is TileMap:
		extra = _tilemap_info(node as TileMap)
	elif node is TileMapLayer:
		extra = _tilemaplayer_info(node as TileMapLayer)
	print(_indent + node.name + " [" + node.get_class() + "]" + extra)
	var saved := _indent
	_indent = saved + "  "
	for child in node.get_children():
		_dump(child)
	_indent = saved


func _tilemap_info(tm: TileMap) -> String:
	if tm.tile_set == null:
		return "  !! NO TILE_SET"
	var out := "  (TileMap) layers=" + str(tm.get_layers_count())
	for layer in range(tm.get_layers_count()):
		var cells := tm.get_used_cells(layer)
		out += "\n" + _indent + "  layer " + str(layer) + ": " + str(cells.size()) + " cells"
		var bounds := _bounds(cells)
		if bounds.size() == 4:
			out += "  extent x[%d..%d] y[%d..%d]" % [bounds[0], bounds[1], bounds[2], bounds[3]]
		for c in cells:
			out += "\n" + _indent + "    cell=(%d,%d) src=%d atlas=(%d,%d) alt=%d" % [
				c.x, c.y,
				tm.get_cell_source_id(layer, c),
				tm.get_cell_atlas_coords(layer, c).x,
				tm.get_cell_atlas_coords(layer, c).y,
				tm.get_cell_alternative_tile(layer, c)
			]
	return out


func _tilemaplayer_info(tl: TileMapLayer) -> String:
	if tl.tile_set == null:
		return "  (TileMapLayer) !! NO TILE_SET"
	var cells := tl.get_used_cells()
	var out := "  (TileMapLayer) cells=" + str(cells.size())
	for c in cells:
		out += "\n" + _indent + "    cell=(%d,%d) src=%d atlas=(%d,%d)" % [
			c.x, c.y,
			tl.get_cell_source_id(c),
			tl.get_cell_atlas_coords(c).x,
			tl.get_cell_atlas_coords(c).y
		]
	return out


func _bounds(cells: Array[Vector2i]) -> Array:
	if cells.is_empty():
		return []
	var min_x := cells[0].x
	var max_x := cells[0].x
	var min_y := cells[0].y
	var max_y := cells[0].y
	for c in cells:
		min_x = mini(min_x, c.x)
		max_x = maxi(max_x, c.x)
		min_y = mini(min_y, c.y)
		max_y = maxi(max_y, c.y)
	return [min_x, max_x, min_y, max_y]
