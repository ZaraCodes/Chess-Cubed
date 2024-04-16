extends Camera3D

@export var movement_speed: float

var zoom_in: bool
var zoom_out: bool

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func _physics_process(delta):
	if Input.is_action_pressed("Rotate Up"):
		get_parent_node_3d().rotate(global_basis.x, -delta)
	if Input.is_action_pressed("Rotate Down"):
		get_parent_node_3d().rotate(global_basis.x, delta)
	if Input.is_action_pressed("Rotate Right"):
		get_parent_node_3d().rotate(global_basis.y, delta)
	if Input.is_action_pressed("Rotate Left"):
		get_parent_node_3d().rotate(global_basis.y, -delta)
	if Input.is_action_pressed("Roll Left"):
		rotate(basis.z, delta)
	if Input.is_action_pressed("Roll Right"):
		rotate(basis.z, -delta)
	if zoom_in:
		position.z -= delta * 20
		if position.z < 13:
			position.z = 13
		zoom_in = false
	if zoom_out:
		position.z += delta * 20
		zoom_out = false

func _on_chess_cube_cube_generated(center):
	get_parent_node_3d().position = center

func _input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			zoom_in = true
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			zoom_out = true
