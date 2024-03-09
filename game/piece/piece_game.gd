extends Node2D

signal moved(dir: Vector2i, success: bool)
signal rotated(dir: int, success: bool)
signal dropped

const Blocks = [
	preload("res://game/tileset/block0.png"),
	preload("res://game/tileset/block1.png"),
	preload("res://game/tileset/block2.png"),
	preload("res://game/tileset/block3.png"),
]

var board_game: Node

var active: bool
var piece: Piece
var down: Vector2i = Vector2i.DOWN

var _rotation_target: float

func _ready():
	active = false
	visible = false


func _process(delta):
	if Input.is_action_just_pressed("rotate_left"):
		down = Piece.rotate_vector(down, -1)
		var success = false
		if active:
			if piece.try_rotate(board_game.board, -1):
				$Sounds/Rotate.play()
				success = true
			else:
				$Sounds/RotateFail.play()
		else:
			$Sounds/RotateFail.play()
		update_position()
		rotated.emit(-1, success)
	if Input.is_action_just_pressed("rotate_right"):
		down = Piece.rotate_vector(down, 1)
		var success = false
		if active:
			if piece.try_rotate(board_game.board, 1):
				$Sounds/Rotate.play()
				success = true
			else:
				$Sounds/RotateFail.play()
		else:
			$Sounds/RotateFail.play()
		update_position()
		rotated.emit(1, success)
	$Blocks.rotation = move_toward($Blocks.rotation, _rotation_target, delta*PI*5.0)
	
	if not active:
		return
	
	var left = Piece.rotate_vector(down, 1)
	var right = Piece.rotate_vector(down, -1)
	var up = Piece.rotate_vector(right, -1)
	
	if Input.is_action_just_pressed("move_left"):
		var success = piece.try_move(board_game.board, left)
		if success:
			update_position()
			$Sounds/Move.play()
		else:
			$Sounds/MoveFail.play()
		moved.emit(left, success)
	if Input.is_action_just_pressed("move_right"):
		var success = piece.try_move(board_game.board, right)
		if success:
			update_position()
			$Sounds/Move.play()
		else:
			$Sounds/MoveFail.play()
		moved.emit(right, success)
	if Input.is_action_just_pressed("move_up"):
		var success = piece.try_move(board_game.board, up)
		if success:
			update_position()
			$Sounds/Move.play()
		else:
			$Sounds/MoveFail.play()
		moved.emit(up, success)
	if Input.is_action_just_pressed("move_down"):
		var success = piece.try_move(board_game.board, down)
		if success:
			update_position()
			$Sounds/Move.play()
		else:
			$Sounds/MoveFail.play()
		moved.emit(down, success)
	if Input.is_action_just_pressed("drop"):
		drop()
		return

func spawn(shape_id: int, rot: int, tile_ids: Array[int], pos: Vector2i) -> bool:
	piece = Piece.new(shape_id, tile_ids, rot, pos)
	
	var shape = Piece.SHAPE[shape_id]
	for i in $Blocks.get_child_count():
		var b = $Blocks.get_child(i)
		var g = $Ghosts.get_child(i)
		var in_shape = i < shape.size()
		if in_shape:
			var tex = Blocks[piece.tile_ids[i] - Board.BLOCK_TILE]
			b.position = shape[i]*16
			b.texture = tex
			g.texture = tex
		b.visible = in_shape
		g.visible = in_shape
	$Blocks.rotation = piece.rotation*PI/2.0
	update_position()
	visible = true
	if not piece.is_overlapped(board_game.board):
		active = true
		return true
	else:
		die()
		return false


func update_position():
	if piece == null:
		return
	position = piece.position*16
	var ghost = piece.get_ghost(board_game.board, down)
	var diff = ghost.position - piece.position
	for i in piece.blocks.size():
		var b = $Blocks.get_child(i)
		var g = $Ghosts.get_child(i)
		g.position = (ghost.blocks[i] + diff)*16
		b.rotation = -piece.rotation*PI/2.0
	_rotation_target = piece.rotation*PI/2.0


func drop():
	var ghost = piece.get_ghost(board_game.board, down)
	for i in piece.blocks.size():
		board_game.set_block(Board.Block.BLOCK, piece.tile_ids[i], ghost.position + ghost.blocks[i])
	active = false
	visible = false
	piece = null
	$Sounds/Drop.play()
	dropped.emit()


func die():
	active = false
	modulate.a = 0.3
	$Sounds/Death.play()


func is_overlapped() -> bool:
	return piece.is_overlapped(board_game.board)
