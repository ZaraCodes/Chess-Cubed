extends Node3D

@export var curve: Curve
var tile_cube = preload("res://Scenes/Tile Cube.tscn")
var turning: bool
var turning_direction: Vector3
var turn_progress: float

var board_x_up := []
var board_x_down := []
var board_y_up := []
var board_y_down := []
var board_z_up := []
var board_z_down := []

var cube_slices := {}


func generate_cube(size: int):
	for x in range(size):
		for y in range(size):
			for z in range(size):
				if is_on_edge(size, x) or is_on_edge(size, y) or is_on_edge(size, z):
					var cube = tile_cube.instantiate()
					if x == 0:
						var tile = cube.add_tile(Vector3i(-1, 0, 0), Vector2i(y, z))
						board_x_down.append(tile)
					elif x == size - 1:
						var tile = cube.add_tile(Vector3i(1, 0, 0), Vector2i(y, z))
						board_x_up.append(tile)
					if y == 0:
						var tile = cube.add_tile(Vector3i(0, -1, 0), Vector2i(x, z))
						board_y_down.append(tile)
					elif y == size - 1:
						var tile = cube.add_tile(Vector3i(0, 1, 0), Vector2i(x, z))
						board_y_up.append(tile)
					if z == 0:
						var tile = cube.add_tile(Vector3i(0, 0, -1), Vector2i(x, y))
						board_z_down.append(tile)
					elif z == size - 1:
						var tile = cube.add_tile(Vector3i(0, 0, 1), Vector2i(x, y))
						board_z_up.append(tile)
					
					cube.position = Vector3(x - size / 2.0 + 0.5, y - size / 2.0 + 0.5, z - size / 2.0 + 0.5)
					add_cube_to_slices(cube, x, y, z)
					add_child(cube)

func add_cube_to_slices(cube: Node3D, x: int, y: int, z: int):
	if not cube_slices.has("x"):
		cube_slices["x"] = {}
	if not cube_slices.has("y"):
		cube_slices["y"] = {}
	if not cube_slices.has("z"):
		cube_slices["z"] = {}
	
	if not cube_slices["x"].has(x):
		cube_slices["x"][x] = []
	if not cube_slices["y"].has(y):
		cube_slices["y"][y] = []
	if not cube_slices["z"].has(z):
		cube_slices["z"][z] = []
	
	cube_slices["x"][x].append(cube)
	cube_slices["y"][y].append(cube)
	cube_slices["z"][z].append(cube)

func add_slice_to_rotator(axis: String, layer: int):
	for element in cube_slices[axis][layer]:
		remove_child(element)
		$Rotator.add_child(element)

func is_on_edge(size: int, value: int):
	return value == 0 or value == size - 1

func start_slice_turn(axis: String, layer: int):
	add_slice_to_rotator(axis, layer)

func turn_slice(delta: float):
	turn_progress += delta / 2.0
	$Rotator.rotation_degrees = turning_direction * 90 * curve.sample(turn_progress)
	if turn_progress >= 1:
		end_slice_turn()

func end_slice_turn():
	$Rotator.rotation_degrees = turning_direction * 90
	turning = false
	print_rich("[color=green]turn finished")
	pass

func _on_turn_button_pressed():
	pass # Replace with function body.

# Called when the node enters the scene tree for the first time.
func _ready():
	generate_cube(8)
	
	turning = true
	turn_progress = 0.0
	turning_direction = Vector3(0, 0, 1)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if turning:
		turn_slice(delta)
