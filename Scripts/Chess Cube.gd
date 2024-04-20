extends Node3D

signal slice_turn_finished()

@export var curve: Curve
@export var tile_coord_label: Label
var tile_cube = preload("res://Scenes/Tile Cube.tscn")
var turning: bool
var turning_direction: Vector3
var turn_progress: float

var cube_slices := {}
var boards := {}
var game_state_cache := {}

var selected_axis: String
var slice: int
var turn_sign: float
var highlighted_tiles := []

signal slice_turned(axis: String, slice_index: int, direction: int)
signal incoming_slice_turn(axis: String, slice_index: int, direction: int)
signal cube_generated(center: Vector3)

func _on_axis_selected(value: int):
	match value:
		0:
			selected_axis = "x"
		1:
			selected_axis = "y"
		2:
			selected_axis = "z"

func _on_slice_updated(value: float):
	slice = int(value)

func generate_cube(size: int):
	for x in range(size):
		for y in range(size):
			for z in range(size):
				if is_on_edge(size, x) or is_on_edge(size, y) or is_on_edge(size, z):
					var cube = tile_cube.instantiate()
					if x == 0:
						var tile = cube.add_tile(Enums.Face.XDOWN, Vector2i(y, z))
						add_tile_to_boards(tile, Enums.Face.XDOWN)
					elif x == size - 1:
						var tile = cube.add_tile(Enums.Face.XUP, Vector2i(y, z))
						add_tile_to_boards(tile, Enums.Face.XUP)
					if y == 0:
						var tile = cube.add_tile(Enums.Face.YDOWN, Vector2i(x, z))
						add_tile_to_boards(tile, Enums.Face.YDOWN)
					elif y == size - 1:
						var tile = cube.add_tile(Enums.Face.YUP, Vector2i(x, z))
						add_tile_to_boards(tile, Enums.Face.YUP)
					if z == 0:
						var tile = cube.add_tile(Enums.Face.ZDOWN, Vector2i(x, y))
						add_tile_to_boards(tile, Enums.Face.ZDOWN)
					elif z == size - 1:
						var tile = cube.add_tile(Enums.Face.ZUP, Vector2i(x, y))
						add_tile_to_boards(tile, Enums.Face.ZUP)
					
					#cube.position = Vector3(x - size / 2.0 + 0.5, y - size / 2.0 + 0.5, z - size / 2.0 + 0.5)
					$Rotator.position = Vector3((size - 1) / 2.0, (size - 1) / 2.0, (size - 1) / 2.0)
					cube.position = Vector3(x, y, z)
					add_cube_to_slices(cube, x, y, z)
					$"Small Cubes".add_child(cube)
	cube_generated.emit($Rotator.position)

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

func add_tile_to_boards(tile: Node3D, direction: Enums.Face):
	if !boards.has(direction):
		boards[direction] = {}
	
	boards[direction]["%s_%s" % [tile.board_position.x, tile.board_position.y]] = tile
	tile.tile_hovered.connect(on_tile_hovered)
	if Client.client_ref != null:
		tile.tile_selected.connect(Client.client_ref.request_possible_moves)
		tile.tile_selected.connect(add_to_highlighted_tiles)


func add_to_highlighted_tiles(tile: Node3D):
	unhighlight_tiles()
	highlighted_tiles.append(tile)


func recalculate_slices_of_cubes():
	cube_slices.clear()
	cube_slices["x"] = {}
	cube_slices["y"] = {}
	cube_slices["z"] = {}
	
	for cube: Node3D in $"Small Cubes".get_children():
		var x := int(round(cube.position.x))
		var y := int(round(cube.position.y))
		var z := int(round(cube.position.z))
		
		if not cube_slices["x"].has(x):
			cube_slices["x"][x] = []
		if not cube_slices["y"].has(y):
			cube_slices["y"][y] = []
		if not cube_slices["z"].has(z):
			cube_slices["z"][z] = []
		
		cube_slices["x"][x].append(cube)
		cube_slices["y"][y].append(cube)
		cube_slices["z"][z].append(cube)

func recalculate_boards():
	var new_boards := {}
	new_boards[Enums.Face.XDOWN] = {}
	new_boards[Enums.Face.XUP] = {}
	new_boards[Enums.Face.YDOWN] = {}
	new_boards[Enums.Face.YUP] = {}
	new_boards[Enums.Face.ZDOWN] = {}
	new_boards[Enums.Face.ZUP] = {}
	
	for direction in boards.keys():
		for tile_position in boards[direction].keys():
			var tile = boards[direction][tile_position]
			var rounded_x = roundi(tile.global_position.x)
			var rounded_y = roundi(tile.global_position.y)
			var rounded_z = roundi(tile.global_position.z)
			
			if tile.global_basis.y.x > .5:
				new_boards[Enums.Face.XUP]["%s_%s" % [rounded_y, rounded_z]] = tile
				set_tile_data(tile, Vector2i(rounded_y, rounded_z), Enums.Face.XUP)
			elif tile.global_basis.y.x < -.5:
				new_boards[Enums.Face.XDOWN]["%s_%s" % [rounded_y, rounded_z]] = tile
				set_tile_data(tile, Vector2i(rounded_y, rounded_z), Enums.Face.XDOWN)
			elif tile.global_basis.y.y > .5:
				new_boards[Enums.Face.YUP]["%s_%s" % [rounded_x, rounded_z]] = tile
				set_tile_data(tile, Vector2i(rounded_x, rounded_z), Enums.Face.YUP)
			elif tile.global_basis.y.y < -.5:
				new_boards[Enums.Face.YDOWN]["%s_%s" % [rounded_x, rounded_z]] = tile
				set_tile_data(tile, Vector2i(rounded_x, rounded_z), Enums.Face.YDOWN)
			elif tile.global_basis.y.z > .5:
				new_boards[Enums.Face.ZUP]["%s_%s" % [rounded_x, rounded_y]] = tile
				set_tile_data(tile, Vector2i(rounded_x, rounded_y), Enums.Face.ZUP)
			elif tile.global_basis.y.z < -.5:
				new_boards[Enums.Face.ZDOWN]["%s_%s" % [rounded_x, rounded_y]] = tile
				set_tile_data(tile, Vector2i(rounded_x, rounded_y), Enums.Face.ZDOWN)
	boards = new_boards


func set_tile_data(tile, board_position: Vector2i, face: int):
	tile.board_position = board_position
	tile.face = face


func add_slice_to_rotator(axis: String, layer: int):
	for node in cube_slices[axis][layer]:
		var global_pos = node.global_position
		var global_rot = node.global_rotation
		$"Small Cubes".remove_child(node)
		$Rotator.add_child(node)
		node.global_position = global_pos
		node.global_rotation = global_rot

func is_on_edge(size: int, value: int):
	return value == 0 or value == size - 1

func start_slice_turn():
	unhighlight_tiles()
	turning = true
	add_slice_to_rotator(selected_axis, slice)
	turn_progress = 0.0
	match selected_axis:
		"x":
			turning_direction = Vector3(1, 0, 0)
		"y":
			turning_direction = Vector3(0, 1, 0)
		"z":
			turning_direction = Vector3(0, 0, 1)
	turning_direction *= turn_sign

func turn_slice(delta: float):
	turn_progress += delta / 2.0
	$Rotator.rotation_degrees = turning_direction * 90 * curve.sample(turn_progress)
	if turn_progress >= 1:
		end_slice_turn()

func end_slice_turn():
	$Rotator.rotation_degrees = turning_direction * 90
	turning = false
	print_rich("[color=green]turn finished")
	for node: Node3D in $Rotator.get_children():
		var global_pos = node.global_position
		var global_rot = node.global_rotation
		$Rotator.remove_child(node)
		$"Small Cubes".add_child(node)
		node.global_position = global_pos
		node.global_rotation = global_rot
	$Rotator.rotation = Vector3.ZERO
	recalculate_slices_of_cubes()
	recalculate_boards()
	check_game_state()
	slice_turn_finished.emit()


func check_game_state():
	for face in boards.keys():
		if not game_state_cache.has(face):
			print_rich("[color=cyan][b]Oh no cached game state and this game state do not have the same faces... %s is missing" % face)
			continue
		for tile_key in boards[face].keys():
			if not game_state_cache[face].has(tile_key):
				print_rich("[color=cyan][b]Oh no cached game state and this game state do not have the same tile keys... %s is missing in [color=red]face %s" % [tile_key, face])
				continue
			var tile = boards[face][tile_key]
			if tile.piece != null:
				if game_state_cache[face][tile_key] == null:
					print_rich("[color=cyan][b]!! FACE %s WE HAVE TO DELETE THE '%s' ON %s TO SYNC !!" % [face, tile.piece.symbol, tile_key])
					tile.piece.free()
					continue
				if game_state_cache[face][tile_key]["symbol"] != tile.piece.symbol:
					print_rich("[color=cyan][b]!! FACE %s WE HAVE TO REPLACE THE '%s' ON %s TO WITH %s!!" % [face, tile.piece.symbol, tile_key, game_state_cache[face][tile_key]])
					tile.piece.free()
					spawn_piece(face, tile_key, game_state_cache[face][tile_key]["symbol"])
					continue
				else:
					pass
			else:
				if game_state_cache[face][tile_key] != null:
					print_rich("[color=cyan][b]!! FACE %s WE HAVE TO SPAWN A '%s' ON %s" % [face, game_state_cache[face][tile_key]["symbol"], tile_key])
					spawn_piece(face, tile_key, game_state_cache[face][tile_key]["symbol"])


func spawn_piece(face: Enums.Face, key: String, piece: String):
	if boards[face][key].piece != null:
		boards[face][key].piece.free()
	
	var new_piece
	match piece:
		"B": # black bishop
			new_piece = load("res://Scenes/Chess Pieces/Black Bishop.tscn").instantiate()
		"b": # white bishop
			new_piece = load("res://Scenes/Chess Pieces/White Bishop.tscn").instantiate()
		"K": # black king
			new_piece = load("res://Scenes/Chess Pieces/Black King.tscn").instantiate()
		"k": # white king
			new_piece = load("res://Scenes/Chess Pieces/White King.tscn").instantiate()
		"N": # black knight
			new_piece = load("res://Scenes/Chess Pieces/Black Knight.tscn").instantiate()
		"n": # white knight
			new_piece = load("res://Scenes/Chess Pieces/White Knight.tscn").instantiate()
		"P": # black pawn
			new_piece = load("res://Scenes/Chess Pieces/Black Pawn.tscn").instantiate()
			pass
		"p": # white pawn
			new_piece = load("res://Scenes/Chess Pieces/White Pawn.tscn").instantiate()
			pass
		"Q": # black queen
			new_piece = load("res://Scenes/Chess Pieces/Black Queen.tscn").instantiate()
		"q": # white queen
			new_piece = load("res://Scenes/Chess Pieces/White Queen.tscn").instantiate()
		"R": # black rook
			new_piece = load("res://Scenes/Chess Pieces/Black Rook.tscn").instantiate()
		"r": # white rook
			new_piece = load("res://Scenes/Chess Pieces/White Rook.tscn").instantiate()
	
	if new_piece != null:
		boards[face][key].add_child(new_piece)
		boards[face][key].piece = new_piece
		boards[face][key].face = face

func _on_turn_button_pressed():
	# check turn
	#start_slice_turn()
	slice_turned.emit(selected_axis, slice, turn_sign)

func start_remote_slice_turn(axis: String, slice_index: int, direction: int):
	incoming_slice_turn.emit(axis, slice_index, direction)
	selected_axis = axis
	slice = slice_index
	turn_sign = direction
	start_slice_turn()


func _on_check_box_toggled(toggled_on):
	if toggled_on:
		turn_sign = 1.0
	else:
		turn_sign = -1.0


func _on_face_selector_item_selected(index):
	for face in range(6):
		for tile_pos in boards[face].keys():
			boards[face][tile_pos].selected = false
	if index < 6:
		for tile_pos in boards[index].keys():
			boards[index][tile_pos].selected = true


func set_new_game_state(new_state: Dictionary):
	if turning:
		game_state_cache = new_state
	else:
		game_state_cache = new_state
		check_game_state()


func on_tile_hovered(coords: Vector2i):
	tile_coord_label.text = "%s %s" % [coords.x, coords.y]


func on_possible_moves_received(data: Array):
	for face_data in data:
		for tile in face_data["possible_moves"]:
			boards[face_data["face"]][tile].selected = true
			highlighted_tiles.append(boards[face_data["face"]][tile])


func unhighlight_tiles():
	for tile in highlighted_tiles:
		tile.selected = false
	highlighted_tiles.clear()


# Called when the node enters the scene tree for the first time.
func _ready():
	generate_cube(8)
	turning = false
	selected_axis = "x"
	turn_sign = -1
	slice = 0
	
	if Client.client_ref == null:
		return
	
	Client.client_ref.slice_move.connect(start_remote_slice_turn)
	slice_turned.connect(Client.client_ref.on_cube_slice_turned)
	Client.client_ref.new_game_state.connect(set_new_game_state)
	Client.client_ref.possible_moves_received.connect(on_possible_moves_received)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if turning:
		turn_slice(delta)
