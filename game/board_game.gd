extends TileMap


@export var symbol_num: int = 10

var modulated_cells: Dictionary

var board: Board

func _ready() -> void:
	var board_size = get_used_rect().size
	board = Board.new(board_size)
	for y in board_size.y:
		for x in board_size.x:
			var t = get_cell_tile_data(1, Vector2i(x, y))
			if t != null:
				board.set_block(Board.Block.WALL, 1, Vector2i(x, y))
			else:
				board.set_block(Board.Block.AIR, -1, Vector2i(x, y))
	board.create_circle_map()
	for y in board_size.y:
		for x in board_size.x:
			var t = get_cell_tile_data(0, Vector2i(x, y))
			if t != null:
				var c = board.circle_map[board.index(Vector2i(x, y))]
				var g = clamp((6.0 - c)/6.0, 0.0, 1.0)
				modulated_cells[Vector2i(x, y)] = Color.DARK_RED.darkened(1.0 - g)
			else:
				board.circle_map[board.index(Vector2i(x, y))] = -1


func _use_tile_data_runtime_update(layer: int, coords: Vector2i) -> bool:
	return layer == 0 and modulated_cells.has(coords)


func _tile_data_runtime_update(layer: int, coords: Vector2i, tile_data: TileData) -> void:
	tile_data.modulate = modulated_cells.get(coords, Color.WHITE)


func set_block(block: Board.Block, tile_id: int, pos: Vector2i):
	board.set_block(block, tile_id, pos)
	set_cell(1, pos, tile_id, Vector2i())


func refresh():
	for y in board.size.y:
		for x in board.size.x:
			var p = Vector2i(x, y)
			set_cell(1, p, board.grid_tile_id[board.index(p)], Vector2i())


func spawn_symbols(num: int):
	var spawnables: Array[Vector2i] = []
	var center = board.size / 2
	for y in board.size.y:
		for x in board.size.x:
			var p = Vector2i(x, y)
			var d = center - p
			if max(abs(d.x), abs(d.y)) < 3:
				continue
			var t = get_cell_tile_data(0, Vector2i(x, y))
			if t == null:
				continue
			if board.grid_block[board.index(p)] != Board.Block.AIR:
				continue
			spawnables.append(p)
	
	for __3wroyliuhsdfglikjdfjgioreutljdbvilsdhgiuewutiopreh3itluuesfokpgiw3r498p0qyugioyqwe3to98__ in num:
		var i = randi() % spawnables.size()
		var p = spawnables[i]
		spawnables.remove_at(i)
		board.set_block(Board.Block.SYMBOL, Board.SYMBOL_TILE + randi() % 4, p)
	refresh()


func try_drop(down: Vector2i) -> bool:
	var ret = board.try_drop(down)
	refresh()
	return ret


func clear_mapped():
	board.clear_mapped()
	refresh()


func clear_one_block() -> bool:
	var ret = board.clear_one_block()
	refresh()
	return ret
