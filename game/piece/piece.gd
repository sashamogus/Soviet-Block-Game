class_name Piece
extends RefCounted

const SHAPE = [
	[Vector2i(0, 0)], # 1 block
	[Vector2i(0, 0), Vector2i(1, 0)], # 2 block I
	[Vector2i(-1, 0), Vector2i(0, 0), Vector2i(1, 0)], # 3 block I
	[Vector2i(0, 0), Vector2i(1, 0), Vector2i(0, 1)], # small L
	[Vector2i(-1, 0), Vector2i(0, 0), Vector2i(1, 0), Vector2i(-1, 1)], # L
	[Vector2i(-1, 0), Vector2i(0, 0), Vector2i(1, 0), Vector2i(0, 1)], # T
	[Vector2i(-1, 0), Vector2i(0, 0), Vector2i(1, 0), Vector2i(1, 1)], # J
	[Vector2i(-1, 0), Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0)], # I
	[Vector2i(0, 0), Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 1)], # O
	[Vector2i(-1, 0), Vector2i(0, 0), Vector2i(0, 1), Vector2i(1, 1)], # GREEN
	[Vector2i(0, 0), Vector2i(1, 0), Vector2i(-1, 1), Vector2i(0, 1)], # PURPLE
]


var shape_id: int
var tile_ids: Array[int]
var rotation: int
var position: Vector2i
var blocks: Array[Vector2i]


static func rotate_vector(vec: Vector2i, dir: int) -> Vector2i:
	if dir == 1:
		return Vector2i(-vec.y, vec.x)
	else:
		return Vector2i(vec.y, -vec.x)


func _init(shape_id: int, tile_ids: Array[int], rotation: int, position: Vector2i):
	self.shape_id = shape_id
	self.tile_ids = tile_ids.duplicate()
	self.rotation = 0
	self.position = position
	blocks = []
	for b in SHAPE[shape_id]:
		blocks.append(b)
	while self.rotation != rotation:
		var dir = sign(rotation - self.rotation)
		force_rotate(dir)


func get_ghost(board: Board, down: Vector2i) -> Piece:
	var ret = Piece.new(shape_id, tile_ids, rotation, position)
	while ret.try_move(board, down):
		pass
	return ret


func try_move(board: Board, move: Vector2i) -> bool:
	position += move
	if is_overlapped(board):
		position -= move
		return false
	return true


func try_rotate(board: Board, dir: int) -> bool:
	force_rotate(dir)
	if is_overlapped(board):
		force_rotate(-dir)
		return false
	return true


func force_rotate(dir: int):
	for i in blocks.size():
		blocks[i] = Piece.rotate_vector(blocks[i], dir)
	rotation += dir


func is_overlapped(board: Board) -> bool:
	for b in blocks:
		if board.get_collision(b + position):
			return true
	return false


