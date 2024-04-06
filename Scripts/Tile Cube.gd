extends Node3D

var tile_x_up = preload("res://Scenes/board_tile_x_up.tscn")
var tile_x_down = preload("res://Scenes/board_tile_x_down.tscn")
var tile_y_up = preload("res://Scenes/board_tile_y_up.tscn")
var tile_y_down = preload("res://Scenes/board_tile_y_down.tscn")
var tile_z_up = preload("res://Scenes/board_tile_z_up.tscn")
var tile_z_down = preload("res://Scenes/board_tile_z_down.tscn")



func add_tile(direction: Vector3i, board_position: Vector2i):
	var hmm = [direction.x, direction.y, direction.z]
	var offset := 0
	var tile
	match hmm:
		[1, 0, 0]:
			tile = tile_x_up.instantiate()
			offset = 1
		[-1, 0, 0]:
			tile = tile_x_down.instantiate()
		[0, 1, 0]:
			tile = tile_y_up.instantiate()
		[0, -1, 0]:
			tile = tile_y_down.instantiate()
			offset = 1
		[0, 0, 1]:
			tile = tile_z_up.instantiate()
		[0, 0, -1]:
			tile = tile_z_down.instantiate()
			offset = 1
		_:
			printerr("No direction matched")
	if tile != null:
		add_child(tile)
		tile.board_position = board_position
		tile.set_texture(offset)
	return tile

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
