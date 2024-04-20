extends Area3D

@export var selected_color: Color

var board_position: Vector2i
var face: Enums.Face
var piece

var hovered: bool:
	set(value):
		hovered_var = value
		evaluate_selection_sprite_visibility()
	get:
		return hovered_var

var hovered_var: bool

var selected: bool:
	set(value):
		selected_var = value
		evaluate_selection_sprite_visibility()
	get:
		return selected_var

var selected_var: bool

signal tile_hovered(coord: Vector2i)
signal tile_unhovered()
signal tile_selected(tile)


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if hovered and piece != null:
		if Input.is_action_just_pressed("select_tile"):
			tile_selected.emit(self)
			selected = true


func set_texture(offset: int):
	if (board_position.x + board_position.y + offset) % 2 == 0:
		set_empty_texture()


func set_empty_texture():
	var img := load("res://Textures/selected_frame.png")
	$"Tile Sprite".texture = img


func show_selection_sprite():
	$"Selection Sprite".show()
	$"Selection Sprite".modulate = selected_color


func hide_selection_sprite():
	$"Selection Sprite".hide()


func evaluate_selection_sprite_visibility():
	if hovered or selected:
		if not $"Selection Sprite".visible:
			show_selection_sprite()
	else:
		if $"Selection Sprite".visible:
			hide_selection_sprite()


func _on_mouse_entered():
	tile_hovered.emit(board_position)
	hovered = true


func _on_mouse_exited():
	tile_unhovered.emit()
	hovered = false
