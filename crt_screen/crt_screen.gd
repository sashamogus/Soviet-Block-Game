extends Panel


func resize(new_size: Vector2):
	var game_scale = $Game.scale.x
	var board_size = $Game.board_game.board.size.x
	size = new_size*game_scale + Vector2.ONE*128
	size.x += 64
	position = -size / 2.0
	$Game.position = (size - Vector2.ONE*16.0*board_size*game_scale) / 2.0
	$Overlay.position = size / 2.0
	$Overlay.scale = (size - Vector2(64.0, 64.0)) / 128.0
	$Labels.position = Vector2(size.x + 32, 0)
