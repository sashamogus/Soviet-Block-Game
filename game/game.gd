extends Node2D


const Levels = [
	preload("res://game/levels/level0.tscn"),
	preload("res://game/levels/level1.tscn"),
	preload("res://game/levels/level2.tscn"),
	preload("res://game/levels/level3.tscn"),
	preload("res://game/levels/level4.tscn"),
]

enum Phase {
	PRESS_START,
	START_PRESSED,
	LEVEL_READY,
	LEVEL_CLEAR,
	GAME_CLEAR,
	GAME_OVER,
	GAME_OVER_WAIT,
	TIME_UP,
	TIME_UP_WAIT,
	READY,
	DEATH,
	CONTROL,
	DROP,
	CLEAR,
}

@export var god: Node
@export var nexts: Node
@export var labels: Node

@export var game_start_label: Node


var board_game: Node

var score: float
var hiscore: float
var lives: int
var level: int
var symbols_current: int
var time: float

var combo: int
var phase: Phase
var _timer: float
var _drop_first: bool


func _ready():
	load_level(0)
	$PieceGame.moved.connect(_moved)
	$PieceGame.rotated.connect(_rotated)
	$PieceGame.dropped.connect(_dropped)
	phase = Phase.PRESS_START
	_timer = 2.0


func _process(delta: float):
	match phase:
		Phase.READY, Phase.CONTROL, Phase.DEATH, Phase.DROP, Phase.CLEAR:
			time -= delta
			if time < 100:
				$Sounds/BGM.pitch_scale = 1.25
			else:
				$Sounds/BGM.pitch_scale = 1.0
			if time < 0:
				lives -= 1
				$PieceGame.active = false
				$PieceGame.visible = false
				$PieceGame.piece = null
				$Sounds/BGM.stop()
				phase = Phase.TIME_UP
				_timer = 1.0
				game_start_label.text = "TIME'S UP!"
				game_start_label.visible = true
	match phase:
		Phase.PRESS_START:
			if Input.is_action_just_pressed("start"):
				score = 0
				lives = 10
				$Sounds/PressStart.play()
				phase = Phase.START_PRESSED
				_timer = 1.0
		Phase.START_PRESSED:
			game_start_label.visible = sin(_timer*TAU*5.0) > 0.0
			_timer -= delta
			if _timer < 0.0:
				load_level(0)
				game_start_label.text = "LEVEL %d\nREADY?" % (level + 1)
				game_start_label.visible = true
				$Sounds/BGM.play()
				$Sounds/BGM.pitch_scale = 1.0
				phase = Phase.LEVEL_READY
				_timer = 3.0
		Phase.LEVEL_READY:
			_timer -= delta
			time = 300
			if _timer < 0.0:
				$PieceGame.piece = null
				board_game.spawn_symbols(board_game.symbol_num)
				symbols_current = board_game.board.get_symbol_count()
				$Sounds/Rebirth.play()
				_timer = 0.1
				game_start_label.visible = false
				phase = Phase.READY
		Phase.LEVEL_CLEAR:
			_timer -= delta
			if _timer < 0.0:
				if time > 0.0:
					time -= 5.0
					time = max(time, -0.1)
					score += 10
					$Sounds/Bonus.play()
					_timer = 0.05 if time > 0.0 else 1.0
				elif board_game.clear_one_block():
					$Sounds/Penalty.play()
					score -= 10
					_timer = 0.1 if board_game.board.is_block_remaining() else 2.0
				else:
					if level + 1 < Levels.size():
						load_level(level + 1)
						game_start_label.text = "LEVEL %d\nREADY?" % (level + 1)
						game_start_label.visible = true
						$Sounds/BGM.play()
						$Sounds/BGM.pitch_scale = 1.0
						phase = Phase.LEVEL_READY
						_timer = 3.0
					else:
						$Sounds/GameClear.play()
						phase = Phase.GAME_CLEAR
						game_start_label.text = "ALL LEVELS CLEAR!\nTHANK YOU FOR PLAYING!"
						game_start_label.visible = true
						_timer = 15.0
		Phase.GAME_CLEAR:
			_timer -= delta
			if _timer < 0.0:
				game_start_label.text = "ALL LEVELS CLEAR!\nTHANK YOU FOR PLAYING!\nPRESS ENTER TO CONTINUE"
				if Input.is_action_just_pressed("start"):
					$Sounds/GameClear.stop()
					game_start_label.text = "PRESS ENTER TO START"
					phase = Phase.PRESS_START
		Phase.GAME_OVER:
			_timer -= delta
			if _timer < 0.0:
				game_start_label.text = "GAME OVER"
				game_start_label.visible = true
				$Sounds/GameOver.play()
				phase = Phase.GAME_OVER_WAIT
				_timer = 3.0
		Phase.GAME_OVER_WAIT:
			_timer -= delta
			if _timer < 0.0:
				game_start_label.text = "PRESS ENTER TO START"
				phase = Phase.PRESS_START
		Phase.TIME_UP:
			_timer -= delta
			if _timer < 0.0:
				if board_game.clear_one_block():
					$Sounds/ClearOneBlock.play()
					score -= 10
					_timer = 0.1
				else:
					phase = Phase.TIME_UP_WAIT
					_timer = 2.0
		Phase.TIME_UP_WAIT:
			_timer -= delta
			if _timer < 0.0:
				if lives <= 0:
					phase = Phase.GAME_OVER
					_timer = 1.0
				else:
					load_level(level)
					game_start_label.text = "LEVEL %d\nREADY?" % (level + 1)
					game_start_label.visible = true
					$Sounds/BGM.play()
					$Sounds/BGM.pitch_scale = 1.0
					phase = Phase.LEVEL_READY
					_timer = 3.0
		Phase.READY:
			combo = 0
			_timer -= delta
			if _timer < 0.0:
				if $PieceGame.piece == null:
					var n = nexts.pop()
					nexts.populate()
					nexts.render()
					god.reset_position(Vector2i())
					if $PieceGame.spawn(n[0], n[1], n[2], board_game.board.size / 2):
						phase = Phase.CONTROL
						$PieceGame.visible = true
					else:
						lives -= 1
						if lives <= 0:
							$Sounds/BGM.stop()
							$PieceGame.visible = false
						phase = Phase.DEATH
						_timer = 0.5
				else:
					if $PieceGame.is_overlapped():
						$PieceGame.die()
						lives -= 1
						if lives <= 0:
							$Sounds/BGM.stop()
							$PieceGame.visible = false
						phase = Phase.DEATH
						_timer = 0.8
					else:
						phase = Phase.CONTROL
						$PieceGame.visible = true
						$PieceGame.modulate = Color.WHITE
						$PieceGame.active = true
						$PieceGame.update_position()
		Phase.DEATH:
			_timer -= delta
			if _timer < 0.0:
				if board_game.clear_one_block():
					$Sounds/ClearOneBlock.play()
					score -= 10
					_timer = 0.1
				else:
					if lives <= 0:
						phase = Phase.GAME_OVER
						_timer = 1.0
					else:
						$Sounds/Rebirth.play()
						$PieceGame.modulate = Color.WHITE
						$PieceGame.active = true
						$PieceGame.update_position()
						phase = Phase.CONTROL
		Phase.DROP:
			_timer -= delta
			if _timer < 0.0:
				var dropped = board_game.try_drop($PieceGame.down)
				if dropped and _drop_first:
					$Sounds/Fall.play()
				_drop_first = false
				if dropped:
					_timer = 0.1
					$PieceGame.update_position()
				else:
					if board_game.board.map_clear():
						combo += 1
						board_game.clear_mapped()
						$Sounds/Clear.play()
						phase = Phase.CLEAR
						_timer = 0.5
					else:
						if symbols_current == 0:
							$Sounds/BGM.stop()
							$Sounds/ClearJingle.play()
							game_start_label.text = "LEVEL CLEAR!"
							game_start_label.visible = true
							$PieceGame.active = false
							$PieceGame.visible = false
							phase = Phase.LEVEL_CLEAR
							_timer = 5.0
						else:
							phase = Phase.READY
							_timer = 0.2
		Phase.CLEAR:
			_timer -= delta
			if _timer < 0.0:
				score += board_game.board.clear_num*10*pow(2, combo - 1)
				symbols_current = board_game.board.get_symbol_count()
				phase = Phase.DROP
				_timer = 0.3
				_drop_first = true
	hiscore = max(hiscore, score)
	_update_label()


func load_level(new_level: int):
	if board_game != null:
		board_game.queue_free()
	
	level = new_level
	board_game = Levels[level].instantiate()
	add_child(board_game)
	move_child(board_game, 0)
	get_parent().resize(board_game.board.size*16)
	$PieceGame.board_game = board_game


func _update_label():
	labels.get_node("Score").text = "SCORE\n%d" % score
	labels.get_node("HiScore").text = "HI-SCORE\n%d" % hiscore
	labels.get_node("Lives").text = "LIVES: %d" % lives
	labels.get_node("Level").text = "LEVEL: %d" % (level + 1)
	labels.get_node("Goal").text = "GOAL: %d/%d" % [board_game.symbol_num - symbols_current, board_game.symbol_num]
	labels.get_node("Time").text = "TIME: %d" % time


func _moved(dir: Vector2i, success: bool):
	if success:
		god.add_movement(dir, scale.x)


func _rotated(dir: int, success: bool):
	god.add_rotation(-dir)
	if phase == Phase.CONTROL:
		if board_game.board.check_drop($PieceGame.down):
			$PieceGame.active = false
			$PieceGame.modulate.a = 0.3
			phase = Phase.DROP
			_drop_first = true
			_timer = 0.3


func _dropped():
	phase = Phase.DROP
	_drop_first = true
	_timer = 0.3
