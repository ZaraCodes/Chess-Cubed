extends Area3D

@export var selected_color: Color

var board_position: Vector2i
var piece

signal tile_selected(coord: Vector2i)
signal tile_deselected()


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func set_texture(offset: int):
	if (board_position.x + board_position.y + offset) % 2 == 0:
		set_empty_texture()

func set_empty_texture():
	var img := load("res://Textures/selected_frame.png")
	$"Tile Sprite".texture = img

func mark_as_selected():
	$"Selection Sprite".show()
	$"Selection Sprite".modulate = selected_color

func mark_as_deselected():
	$"Selection Sprite".hide()

func _on_mouse_entered():
	tile_selected.emit(board_position)
	mark_as_selected()
	if piece != null:
		if piece.unlimited_distance:
			pass
		else:
			pass


func _on_mouse_exited():
	tile_deselected.emit()
	mark_as_deselected()

