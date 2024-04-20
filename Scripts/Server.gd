extends Node

signal start_server_command_received(port: int)
#signal send_to_single_peer(peer_id: int, message: Variant)

## Websocket Server
@export var wss: WebSocketServer

var port: int
var players := {}

var cube_size: int
var game_state := {
	Enums.Face.XUP: {},
	Enums.Face.XDOWN: {},
	Enums.Face.YUP: {},
	Enums.Face.YDOWN: {},
	Enums.Face.ZUP: {},
	Enums.Face.ZDOWN: {},
}

var pieces := {}

func generate_cube(size: int):
	cube_size = size
	for x in range(size):
		for y in range(size):
			for side in game_state.keys():
				game_state[side]["%s_%s" % [x, y]] = ""
	game_state[Enums.Face.YUP]["0_1"] = "B"
	game_state[Enums.Face.YUP]["1_1"] = "k"
	game_state[Enums.Face.YUP]["2_1"] = "B"
	#game_state[Enums.Face.YUP]["3_1"] = "B"
	#game_state[Enums.Face.YUP]["4_1"] = "B"
	game_state[Enums.Face.YUP]["5_1"] = "B"
	game_state[Enums.Face.YUP]["6_1"] = "K"
	game_state[Enums.Face.YUP]["6_6"] = "b"
	game_state[Enums.Face.YUP]["7_1"] = "B"


func load_piece_data(symbol: String):
	symbol = symbol.to_lower()
	if FileAccess.file_exists("res://Scripts/Moves/%s.json" % symbol):
		var file := FileAccess.open("res://Scripts/Moves/%s.json" % symbol, FileAccess.READ)
		var data = JSON.parse_string(file.get_as_text())
		file.close()
		pieces[symbol] = data


func load_default_pieces():
	load_piece_data("b")
	load_piece_data("k")


func rotate_slice(axis: Enums.SliceAxis, slice_index: int, direction: int):
	if axis == Enums.SliceAxis.X:
		if direction > 0:
			rotate_slice_x_positive(slice_index)
		elif direction < 0:
			rotate_slice_x_negative(slice_index)
	elif axis == Enums.SliceAxis.Y:
		if direction > 0:
			rotate_slice_y_positive(slice_index)
		elif direction < 0:
			rotate_slice_y_negative(slice_index)
	elif axis == Enums.SliceAxis.Z:
		if direction > 0:
			rotate_slice_z_positive(slice_index)
		elif direction < 0:
			rotate_slice_z_negative(slice_index)


func rotate_face_left(face: Dictionary) -> Dictionary:
	var new_face := {}
	for row in range(cube_size):
		for column in range(cube_size):
			var new_key := "%s_%s" % [row, column]
			var old_key := "%s_%s" % [column, cube_size - 1 - row]
			new_face[new_key] = face[old_key]
	return new_face


func rotate_face_right(face: Dictionary) -> Dictionary:
	var new_face := {}
	for row in range(cube_size):
		for column in range(cube_size):
			var new_key := "%s_%s" % [row, column]
			var old_key := "%s_%s" % [cube_size - 1 - column, row]
			new_face[new_key] = face[old_key]
	return new_face


func rotate_slice_with_inversion(slice: int, old_face: Enums.Face, new_face: Enums.Face, new_state: Dictionary) -> Dictionary:
	for row in range(cube_size):
		var old_key = "%s_%s" % [slice, row]
		var new_key = "%s_%s" % [slice, cube_size - 1 - row]
		new_state[new_face][new_key] = game_state[old_face][old_key]
	return new_state


func rotate_slice_without_inversion(slice: int, old_face: Enums.Face, new_face: Enums.Face, new_state: Dictionary) -> Dictionary:
	for row in range(cube_size):
		var key = "%s_%s" % [slice, row]
		new_state[new_face][key] = game_state[old_face][key]
	return new_state


func rotate_slice_x_positive(slice: int):
	# yup becomes zup
	var new_state := game_state.duplicate(true)
	
	# zdown -> yup no inversion
	new_state = rotate_slice_without_inversion(slice, Enums.Face.ZDOWN, Enums.Face.YUP, new_state)
	# yup -> zup inversion
	new_state = rotate_slice_with_inversion(slice, Enums.Face.YUP, Enums.Face.ZUP, new_state)
	# zup -> ydown no inversion
	new_state = rotate_slice_without_inversion(slice, Enums.Face.ZUP, Enums.Face.YDOWN, new_state)
	# ydown -> zdown inversion
	new_state = rotate_slice_with_inversion(slice, Enums.Face.YDOWN, Enums.Face.ZDOWN, new_state)
	
	if slice == 0:
		new_state[Enums.Face.XDOWN] = rotate_face_left(game_state[Enums.Face.XDOWN])
	elif slice == cube_size - 1:
		new_state[Enums.Face.XUP] = rotate_face_left(game_state[Enums.Face.XUP])
	
	game_state = new_state


func rotate_slice_x_negative(slice: int):
	# yup becomes zdown
	var new_state := game_state.duplicate(true)
	
	# yup -> zdown
	new_state = rotate_slice_without_inversion(slice, Enums.Face.YUP, Enums.Face.ZDOWN, new_state)
	# zdown -> ydown
	new_state = rotate_slice_with_inversion(slice, Enums.Face.ZDOWN, Enums.Face.YDOWN, new_state)
	# ydown -> zup
	new_state = rotate_slice_without_inversion(slice, Enums.Face.YDOWN, Enums.Face.ZUP, new_state)
	# zup -> yup
	new_state = rotate_slice_with_inversion(slice, Enums.Face.ZUP, Enums.Face.YUP, new_state)
	
	if slice == 0:
		new_state[Enums.Face.XDOWN] = rotate_face_right(game_state[Enums.Face.XDOWN])
	elif slice == cube_size - 1:
		new_state[Enums.Face.XUP] = rotate_face_right(game_state[Enums.Face.XUP])
	
	game_state = new_state


func rotate_slice_y_positive(slice: int):
	# xup becomes zdown
	var new_state := game_state.duplicate(true)
	
	# xup -> zdown
	for row in range(cube_size):
		var old_key = "%s_%s" % [slice, row]
		var new_key = "%s_%s" % [row, slice]
		new_state[Enums.Face.ZDOWN][new_key] = game_state[Enums.Face.XUP][old_key]
	
	# zdown -> xdown
	for row in range(cube_size):
		var old_key = "%s_%s" % [row, slice]
		var new_key = "%s_%s" % [slice, cube_size - 1 - row]
		new_state[Enums.Face.XDOWN][new_key] = game_state[Enums.Face.ZDOWN][old_key]
	
	# xdown -> zup
	for row in range(cube_size):
		var old_key = "%s_%s" % [slice, row]
		var new_key = "%s_%s" % [row, slice]
		new_state[Enums.Face.ZUP][new_key] = game_state[Enums.Face.XDOWN][old_key]

	# zup -> xup
	for row in range(cube_size):
		var old_key = "%s_%s" % [row, slice]
		var new_key = "%s_%s" % [slice, cube_size - 1 - row]
		new_state[Enums.Face.XUP][new_key] = game_state[Enums.Face.ZUP][old_key]
	
	if slice == 0:
		new_state[Enums.Face.YDOWN] = rotate_face_right(game_state[Enums.Face.YDOWN])
	elif slice == cube_size - 1:
		new_state[Enums.Face.YUP] = rotate_face_right(game_state[Enums.Face.YUP])
	
	game_state = new_state


func rotate_slice_y_negative(slice: int):
	# xup becomes zup
	var new_state := game_state.duplicate(true)
	
	# xup -> zup
	for row in range(cube_size):
		var old_key = "%s_%s" % [slice, row]
		var new_key = "%s_%s" % [cube_size - 1 - row, slice]
		new_state[Enums.Face.ZUP][new_key] = game_state[Enums.Face.XUP][old_key]

	# zup -> xdown
	for row in range(cube_size):
		var old_key = "%s_%s" % [row, slice]
		var new_key = "%s_%s" % [slice, row]
		new_state[Enums.Face.XDOWN][new_key] = game_state[Enums.Face.ZUP][old_key]
	
	# xdown -> zdown
	for row in range(cube_size):
		var old_key = "%s_%s" % [slice, cube_size - 1 - row]
		var new_key = "%s_%s" % [row, slice]
		new_state[Enums.Face.ZDOWN][new_key] = game_state[Enums.Face.XDOWN][old_key]
	
	# zdown -> xup
	for row in range(cube_size):
		var old_key = "%s_%s" % [row, slice]
		var new_key = "%s_%s" % [slice, row]
		new_state[Enums.Face.XUP][new_key] = game_state[Enums.Face.ZDOWN][old_key]
	
	if slice == 0:
		new_state[Enums.Face.YDOWN] = rotate_face_left(game_state[Enums.Face.YDOWN])
	elif slice == cube_size - 1:
		new_state[Enums.Face.YUP] = rotate_face_left(game_state[Enums.Face.YUP])
	
	game_state = new_state


func rotate_slice_z_positive(slice: int):
	# yup becomes xdown
	var new_state := game_state.duplicate(true)
	
	# yup -> xdown
	for row in range(cube_size):
		var key = "%s_%s" % [row, slice]
		new_state[Enums.Face.XDOWN][key] = game_state[Enums.Face.YUP][key]
	
	# xdown -> ydown
	for row in range(cube_size):
		var old_key = "%s_%s" % [row, slice]
		var new_key = "%s_%s" % [cube_size - 1 - row, slice]
		new_state[Enums.Face.YDOWN][new_key] = game_state[Enums.Face.XDOWN][old_key]
	
	# ydown -> xup
	for row in range(cube_size):
		var key = "%s_%s" % [row, slice]
		new_state[Enums.Face.XUP][key] = game_state[Enums.Face.YDOWN][key]
	
	# xup -> yup
	for row in range(cube_size):
		var old_key = "%s_%s" % [row, slice]
		var new_key = "%s_%s" % [cube_size - 1 - row, slice]
		new_state[Enums.Face.YUP][new_key] = game_state[Enums.Face.XUP][old_key]
	
	if slice == 0:
		new_state[Enums.Face.ZDOWN] = rotate_face_left(game_state[Enums.Face.ZDOWN])
	elif slice == cube_size - 1:
		new_state[Enums.Face.ZUP] = rotate_face_left(game_state[Enums.Face.ZUP])
	
	game_state = new_state


func rotate_slice_z_negative(slice: int):
	# yup becomes xup
	var new_state := game_state.duplicate(true)
	
	# yup -> xup
	for row in range(cube_size):
		var old_key = "%s_%s" % [row, slice]
		var new_key = "%s_%s" % [cube_size - 1 - row, slice]
		new_state[Enums.Face.XUP][new_key] = game_state[Enums.Face.YUP][old_key]
	
	# xup -> ydown
	for row in range(cube_size):
		var key = "%s_%s" % [row, slice]
		new_state[Enums.Face.YDOWN][key] = game_state[Enums.Face.XUP][key]
	
	# ydown -> xdown
	for row in range(cube_size):
		var old_key = "%s_%s" % [row, slice]
		var new_key = "%s_%s" % [cube_size - 1 - row, slice]
		new_state[Enums.Face.XDOWN][new_key] = game_state[Enums.Face.YDOWN][old_key]
	
	# xdown -> yup
	for row in range(cube_size):
		var key = "%s_%s" % [row, slice]
		new_state[Enums.Face.YUP][key] = game_state[Enums.Face.XDOWN][key]
	
	if slice == 0:
		new_state[Enums.Face.ZDOWN] = rotate_face_right(game_state[Enums.Face.ZDOWN])
	elif slice == cube_size - 1:
		new_state[Enums.Face.ZUP] = rotate_face_right(game_state[Enums.Face.ZUP])
	
	game_state = new_state


func start_server():
	if port > 0:
		generate_cube(8) # replace this later with game settings
		load_default_pieces()
		start_server_command_received.emit(port)
	else:
		print("Server didn't start: Invalid port")


# reacting to server signals
func _on_message_received(peer_id: int, message: Variant):
	print("Message received from %s: %s " % [peer_id, message])
	
	if message.has("type"):
		if message["type"] == Enums.MessageType.PLAYER_EXISTS:
			handle_player_exists(peer_id, message)
		elif message["type"] == Enums.MessageType.PLAYER_COUNT_CHECK:
			handle_player_count_check(peer_id, message)
		elif message["type"] == Enums.MessageType.ADD_PLAYER:
			handle_add_player(peer_id, message)
		elif message["type"] == Enums.MessageType.CHAT_MESSAGE:
			handle_incoming_chat_message(peer_id, message)
		elif message["type"] == Enums.MessageType.MOVE:
			handle_move_message(peer_id, message)
		elif message["type"] == Enums.MessageType.POSSIBLE_MOVES_REQUEST:
			handle_possible_moves_request(message)


func handle_player_exists(peer_id: int, message: Variant):
	if not message.has("player_name") or does_player_exist(message["player_name"]):
		var response := { "type": Enums.MessageType.PLAYER_EXISTS, "value": true }
		wss.send_to_peer(peer_id, response)
	else:
		var response := { "type": Enums.MessageType.PLAYER_EXISTS, "value": false }
		wss.send_to_peer(peer_id, response)


func handle_player_count_check(peer_id: int, message: Variant):
	var response := {}
	if message.has("role"):
		var player_count := get_player_count()
		if player_count > 1:
			response = { "type": Enums.MessageType.PLAYER_COUNT_CHECK, "result": Enums.PlayerCountResult.TOO_MANY_PLAYERS }
		else:
			response = { "type": Enums.MessageType.PLAYER_COUNT_CHECK, "result": Enums.PlayerCountResult.VALID }
	else:
		response = { "type": Enums.MessageType.PLAYER_COUNT_CHECK, "result": Enums.PlayerCountResult.MISSING_ROLE }
	wss.send_to_peer(peer_id, response)


func handle_add_player(peer_id: int, message: Variant):
	var response := {}
	if not message.has("player_name"):
		response = { "type": Enums.MessageType.ADD_PLAYER, "result": Enums.AddPlayerResult.MISSING_NAME, "player_name": "" }
	elif not message.has("role"):
		response = { "type": Enums.MessageType.ADD_PLAYER, "result": Enums.AddPlayerResult.MISSING_ROLE, "player_name": "" }
	elif does_player_exist(message["player_name"]):
		response = { "type": Enums.MessageType.ADD_PLAYER, "result": Enums.AddPlayerResult.ALREADY_EXISTS, "player_name": message["player_name"] }
	elif message["role"] == Enums.PlayerRole.PLAYER and get_player_count() > 1:
		response = { "type": Enums.MessageType.ADD_PLAYER, "result": Enums.AddPlayerResult.TOO_MANY_PLAYERS, "player_name": message["player_name"] }
	else:
		add_player(message["player_name"], peer_id, message["role"])
		response = { "type": Enums.MessageType.ADD_PLAYER, "result": Enums.AddPlayerResult.SUCCESS, "player_name": message["player_name"] }
	wss.send_to_peer(peer_id, response)


func handle_incoming_chat_message(peer_id: int, message: Variant):
	var response := {}
	if not message.has("text"):
		response = { "type": Enums.MessageType.CHAT_MESSAGE, "result": Enums.ChatMessageResult.TEXT_MISSING, "message": {} }
		# do nothing
	elif peer_id not in players.keys():
		response = { "type": Enums.MessageType.CHAT_MESSAGE, "result": Enums.ChatMessageResult.PLAYER_UNKNOWN, "message": {} }
		# do nothing
	else:
		response = { "type": Enums.MessageType.CHAT_MESSAGE, "message": { "player_name": players[peer_id]["player_name"], "text": message["text"] } }
		send_to_players(response)


func handle_move_message(peer_id: int, message: Variant):
	if not message.has("move_type") and not message.has("move_data"):
		print_rich("[b][color=red]Move type or move data missing")
		return  # this should probably notify the client that their message was faulty
	
	if message["move_type"] == Enums.MoveType.SLICE:
		if not message["move_data"].has("axis") or not message["move_data"].has("slice_index") or not message["move_data"].has("direction"):
			print_rich("[b][color=red]axis or slice_index or direction missing")
			return
		
		# add check if player has slice moves available
		
		var old_state = game_state.duplicate(true)
		rotate_slice(message["move_data"]["axis"], message["move_data"]["slice_index"], message["move_data"]["direction"])
		var new_game_state := {
			"type": Enums.MessageType.GAME_STATE,
			"old_state": old_state,
			"new_state": game_state,
			"move_type": Enums.MoveType.SLICE,
			"move_data": {
				"slice_index": message["move_data"]["slice_index"],
				"axis": message["move_data"]["axis"],
				"direction": message["move_data"]["direction"]
			}
		}
		send_to_players(new_game_state)
	else:
		print("MVOE TYPE?????? WHY ARE YOU NOT SLICE??????????")


func handle_possible_moves_request(message: Dictionary):
	if not message.has("data"):
		print_rich("[color=red]Data missing from possible moves request")
		return
	if not message["data"].has("face"):
		print_rich("[color=red]Face missing from data")
		return
	if not message["data"].has("board_position"):
		print_rich("[color=red]Board position missing from data")
		return
	
	var board_position = message["data"]["board_position"]
	var face = message["data"]["face"]
	var piece = game_state[face][board_position]
	if piece == "":
		print_rich("[color=blue]Tile is empty")
		return
	
	var lowercase: bool = piece == piece.to_lower()
	piece = piece.to_lower()
	if piece not in pieces.keys():
		print_rich("[color=red] '%s' Unknown piece" % piece)
		return
	
	var piece_data = pieces[piece]
	var board_x := int(board_position.split("_")[0])
	var board_y := int(board_position.split("_")[1])

	var possible_moves := []
	for possible_move in piece_data["moves"]:
		# print_rich("[color=yellow][SERVER]: [color=white]" + str(possible_move))
		var x = board_x + possible_move[0]
		var y = board_y + possible_move[1]
		
		while x < cube_size and x >= 0 and y < cube_size and y >= 0:
			var new_tile = "%s_%s" % [x, y]
			if game_state[face][new_tile] != "":
				var new_piece = game_state[face][new_tile]
				var new_piece_lowercase: bool = new_piece == new_piece.to_lower()
				
				if new_piece_lowercase == lowercase:
					break
				if new_tile not in possible_moves:
					possible_moves.append(new_tile)
				break
			
			if new_tile not in possible_moves:
				possible_moves.append(new_tile)
			if not piece_data["infinite_distance"]:
				break
			x += possible_move[0]
			y += possible_move[1]
	
	var response := {
		"type": Enums.MessageType.POSSIBLE_MOVES_REQUEST,
		"data": [{
			"possible_moves": possible_moves,
			"face": face
		}]
	}
	send_to_players(response)


func _on_client_connected(peer_id: int):
	print("Client %s connected" % peer_id)
	var response := { "type": Enums.MessageType.WELCOME, "peer_id": peer_id }
	wss.send_to_peer(peer_id, response)


func _on_client_disconnected(peer_id: int):
	print("Client %s disconnected" % peer_id)


func _on_server_listening(listening: Error):
	if listening == Error.OK:
		print("Server is now listening.")
	else:
		print("Server did not start listening.")


func _on_panel_container_port_changed(new_port: int):
	port = new_port


func does_player_exist(player: String) -> bool:
	for key in players.keys():
		if players[key]["player_name"] == player:
			return true
	return false


func add_player(player: String, peer_id: int, role: Enums.PlayerRole):
	if not does_player_exist(player):
		players[peer_id] = { "player_name": player, "role": role }
		send_join_message(peer_id)


func get_player_count() -> int:
	return count_player_type(Enums.PlayerRole.PLAYER)


func get_spectator_count() -> int:
	return count_player_type(Enums.PlayerRole.SPECTATOR)


func count_player_type(player_type: Enums.PlayerRole) -> int:
	var counter := 0
	for key in players.keys():
		if players[key]["role"] == player_type:
			counter += 1
	return counter


func send_to_players(message: Dictionary):
	for key in players.keys():
		wss.send_to_peer(key, message)


func send_join_message(peer_id: int):
	var message := { "type": Enums.MessageType.JOIN_MESSAGE, "player": players[peer_id], "peer_id": peer_id }
	send_to_players(message)
