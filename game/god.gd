extends Node2D


var _target_position: Vector2
var _target_rotation: float



func _process(delta):
	$Anchor.position = $Anchor.position.move_toward(_target_position, delta*3000.0)
	rotation = move_toward(rotation, _target_rotation, delta*PI*5.0)


func reset_position(offset: Vector2):
	_target_position = offset


func add_movement(dir: Vector2i, s: float):
	_target_position -= Vector2(dir)*16*s
	$Anchor.position = _target_position


func add_rotation(dir: int):
	_target_rotation += float(dir)*PI/2

