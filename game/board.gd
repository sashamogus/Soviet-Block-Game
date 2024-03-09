class_name Board
extends RefCounted

const BLOCK_TILE = 2
const SYMBOL_TILE = 6

enum Block {
	AIR,
	WALL,
	BLOCK,
	SYMBOL,
}


var size: Vector2i
var grid_block: Array[Block]
var grid_tile_id: Array[int]
var circle_map: Array[int]
var clear_map: Array[bool]
var clear_num: int


func _init(size: Vector2i):
	self.size = size
	grid_block.resize(size.x*size.y)
	grid_tile_id.resize(size.x*size.y)
	circle_map.resize(size.x*size.y)
	clear_map.resize(size.x*size.y)


func create_circle_map():
	for i in circle_map.size():
		circle_map[i] = 0 if grid_block[i] == Block.WALL else -1
	
	var changed = true
	while changed:
		changed = false
		var changes: Array[int] = []
		changes.resize(circle_map.size())
		changes.fill(-1)
		
		# record change to the circle map
		for i in circle_map.size():
			if circle_map[i] != -1:
				continue
			var nei = [i - 1, i + 1, i - size.x, i + size.x]
			var max_nei = -1
			for n in nei:
				if n < 0 || n >= circle_map.size():
					continue
				max_nei = max(max_nei, circle_map[n])
			if max_nei != -1:
				changes[i] = max_nei + 1
				changed = true
		
		# apply changes
		for i in changes.size():
			if changes[i] != -1:
				circle_map[i] = changes[i]


func index(v: Vector2i):
	return v.x + v.y*size.x


func set_block(block: Block, tile_id: int, pos: Vector2i):
	var i = index(pos)
	grid_block[i] = block
	grid_tile_id[i] = tile_id


func get_collision(pos: Vector2i) -> bool:
	var i = index(pos)
	if i < 0 or i >= size.x*size.y:
		return true
	return grid_block[i] != Block.AIR


func get_symbol_count() -> int:
	var count = 0
	for y in size.y:
		for x in size.x:
			var pos = Vector2i(x, y)
			var i = index(pos)
			if grid_block[i] == Block.SYMBOL:
				count += 1
	return count

func check_drop(down: Vector2i) -> bool:
	if down.x == 0:
		var y = 0 if down.y == -1 else size.y - 1
		while 0 <= y and y < size.y:
			for x in size.x:
				var p = Vector2i(x, y)
				var i = index(p)
				var n = p + down
				if grid_block[i] == Block.BLOCK and not get_collision(n):
					return true
			y -= down.y
	else:
		var x = 0 if down.x == -1 else size.x - 1
		while 0 <= x and x < size.x:
			for y in size.y:
				var p = Vector2i(x, y)
				var i = index(p)
				var n = p + down
				if grid_block[i] == Block.BLOCK and not get_collision(n):
					return true
			x -= down.x
	return false


func try_drop(down: Vector2i) -> bool:
	var ret = false
	if down.x == 0:
		var y = 0 if down.y == -1 else size.y - 1
		while 0 <= y and y < size.y:
			for x in size.x:
				var p = Vector2i(x, y)
				var i = index(p)
				var n = p + down
				if grid_block[i] == Block.BLOCK and not get_collision(n):
					set_block(Block.BLOCK, grid_tile_id[i], n)
					set_block(Block.AIR, -1, p)
					ret = true
			y -= down.y
	else:
		var x = 0 if down.x == -1 else size.x - 1
		while 0 <= x and x < size.x:
			for y in size.y:
				var p = Vector2i(x, y)
				var i = index(p)
				var n = p + down
				if grid_block[i] == Block.BLOCK and not get_collision(n):
					set_block(Block.BLOCK, grid_tile_id[i], n)
					set_block(Block.AIR, -1, p)
					ret = true
			x -= down.x
	return ret


func map_clear() -> bool:
	return _map_clear_puyo()


#region puyopuyo style clear
func _map_clear_puyo() -> bool:
	var ret = false
	clear_map.fill(false)
	clear_num = 0
	for y in size.y:
		for x in size.x:
			var pos = Vector2i(x, y)
			var i = index(pos)
			if _get_color(pos) != -1 and clear_map[i] == false:
				if _map_cluster(pos):
					ret = true
					return ret # comment this line to make simul not a combo
	return ret


func _map_cluster(pos: Vector2i) -> bool:
	var color = _get_color(pos)
	var coords: Array[Vector2i] = [pos]
	var i = 0
	while i < coords.size():
		var p = coords[i]
		var nei: Array[Vector2i] = [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]
		for ne in nei:
			var n = p + ne
			if color == _get_color(n) and not coords.has(n):
				coords.append(n)
		i += 1
	if coords.size() >= 4:
		clear_num += coords.size()
		for p in coords:
			clear_map[index(p)] = true
		return true
	return false
#endregion


#region dr.mario style clear
func _map_clear_drmario() -> bool:
	var ret = false
	clear_map.fill(false)
	clear_num = 0
	for y in size.y:
		for x in size.x:
			var pos = Vector2i(x, y)
			var i = index(pos)
			if _get_color(pos) != -1 and clear_map[i] == false:
				if _map_axis(pos, Vector2i(1, 0)):
					ret = true
				if _map_axis(pos, Vector2i(0, 1)):
					ret = true
				if _map_axis(pos, Vector2i(1, 1)):
					ret = true
				if _map_axis(pos, Vector2i(1, -1)):
					ret = true
	return ret


func _map_axis(pos: Vector2i, axis: Vector2i) -> bool:
	var color = _get_color(pos)
	var count = 1
	
	# check forwardest position
	var p = pos + axis
	var f = pos
	while _get_color(p) == color:
		count += 1
		f = p
		p += axis
	
	# check backwardest position
	p = pos - axis
	var b = pos
	while _get_color(p) == color:
		count += 1
		b = p
		p -= axis
	
	if count >= 4:
		clear_num += count
		p = b
		while p != f + axis:
			clear_map[index(p)] = true
			p += axis
		return true
	return false
#endregion


func _get_color(pos: Vector2i) -> int:
	var color = grid_tile_id[index(pos)]
	match grid_block[index(pos)]:
		Block.BLOCK:
			color -= BLOCK_TILE
		Block.SYMBOL:
			color -= SYMBOL_TILE
		_:
			color = -1
	return color


func clear_mapped():
	for y in size.y:
		for x in size.x:
			var pos = Vector2i(x, y)
			var i = index(pos)
			if clear_map[i]:
				set_block(Block.AIR, -1, pos)


func is_block_remaining() -> bool:
	for y in size.y:
		for x in size.x:
			var pos = Vector2i(x, y)
			var i = index(pos)
			if grid_block[i] == Block.BLOCK:
				return true
	return false


func clear_one_block() -> bool:
	for y in size.y:
		for x in size.x:
			var pos = Vector2i(x, y)
			var i = index(pos)
			if grid_block[i] == Block.BLOCK:
				set_block(Block.AIR, -1, pos)
				return true
	return false

