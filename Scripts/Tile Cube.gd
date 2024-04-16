extends Node3D

var tile_x_up = preload("res://Scenes/board_tile_x_up.tscn")
var tile_x_down = preload("res://Scenes/board_tile_x_down.tscn")
var tile_y_up = preload("res://Scenes/board_tile_y_up.tscn")
var tile_y_down = preload("res://Scenes/board_tile_y_down.tscn")
var tile_z_up = preload("res://Scenes/board_tile_z_up.tscn")
var tile_z_down = preload("res://Scenes/board_tile_z_down.tscn")



func add_tile(direction: Enums.Face, board_position: Vector2i):
	var offset := 0
	var tile
	match direction:
		Enums.Face.XUP:
			tile = tile_x_up.instantiate()
			offset = 1
		Enums.Face.XDOWN:
			tile = tile_x_down.instantiate()
		Enums.Face.YUP:
			tile = tile_y_up.instantiate()
		Enums.Face.YDOWN:
			tile = tile_y_down.instantiate()
			offset = 1
		Enums.Face.ZUP:
			tile = tile_z_up.instantiate()
		Enums.Face.ZDOWN:
			tile = tile_z_down.instantiate()
			offset = 1
		_:
			printerr("No direction matched")
	if tile != null:
		$Tiles.add_child(tile)
		tile.board_position = board_position
		tile.set_texture(offset)
	return tile

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
