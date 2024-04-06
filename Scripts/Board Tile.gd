extends Area3D

@export var selected_color: Color

var board_position: Vector2i


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
	

func _on_mouse_entered():
	$"Selection Sprite".show()
	$"Selection Sprite".modulate = selected_color


func _on_mouse_exited():
	$"Selection Sprite".hide()

