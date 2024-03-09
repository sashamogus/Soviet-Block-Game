extends TileMap

const POSITIONS = [
	Vector2i(3, 3),
	Vector2i(3, 9),
	Vector2i(3, 15),
	Vector2i(3, 21),
]


var shape_ids: Array[int]
var rotations: Array[int]
var tile_ids: Array


func _ready():
	populate()
	render()


func pop() -> Array:
	var ret = []
	ret.append(shape_ids.pop_front())
	ret.append(rotations.pop_front())
	ret.append(tile_ids.pop_front())
	return ret


func populate():
	while shape_ids.size() < POSITIONS.size():
		_generate()


func render():
	for i in shape_ids.size():
		_clear_square(POSITIONS[i] - Vector2i(2, 2))
		var piece = Piece.new(shape_ids[i], tile_ids[i], rotations[i], Vector2i())
		for j in piece.blocks.size():
			var p = POSITIONS[i] + piece.blocks[j]
			var t = piece.tile_ids[j]
			set_cell(0, p, t, Vector2i())


func _clear_square(top_left: Vector2i):
	for y in 5:
		for x in 5:
			var p = top_left + Vector2i(x, y)
			set_cell(0, p, -1)


func _generate():
	var shape_id = randi() % Piece.SHAPE.size()
	var rot = randi() % 4
	
	var tile_id: Array[int] = []
	for i in Piece.SHAPE[shape_id].size():
		tile_id.append(Board.BLOCK_TILE + (randi() % 4))
	
	shape_ids.append(shape_id)
	rotations.append(rot)
	tile_ids.append(tile_id)

