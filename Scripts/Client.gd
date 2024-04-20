class_name Client
extends Node

signal connected_to_server()
signal on_player_exists(request: Dictionary)
signal player_exists(value: bool)
signal player_role_valid(value: bool)
signal hide_name_window()
signal show_chat_window()
signal player_count_is_valid(value: bool)
signal send_join_message(data: Dictionary)
signal send_chat_message(data: Dictionary)
signal slice_move(axis: String, slice_index: int)
signal new_game_state(game_state: Dictionary)
signal possible_moves_received(data: Array)

static var client_ref: Client
var peer_id: int

var awaiting_possible_moves: bool = false

## Websocket Client
@export var wsc: WebSocketClient

# distribute old state + move = new state
var turn_sequence := []

var url: String

func connect_to_server():
	wsc.connect_to_url(url)

# client signals
func _on_connection_failed(err: Error):
	print("Connection to the server failed with Error %s" % err)

func _on_server_connected():
	print("Connected to server established")
	client_ref = self
	connected_to_server.emit()

func _on_connection_closed():
	print("Connection closed")

func _on_message_received(message: Variant):
	if peer_id == 0:
		print("Message received: %s" % message)
	else:
		print("Message received on client %s: %s" % [peer_id, message])
	
	if message.has("type"):
		if message["type"] == Enums.MessageType.PLAYER_EXISTS:
			handle_player_exists(message)
		elif message["type"] == Enums.MessageType.ADD_PLAYER:
			handle_add_player(message)
		elif message["type"] == Enums.MessageType.PLAYER_COUNT_CHECK:
			handle_player_count_check(message)
		elif message["type"] == Enums.MessageType.WELCOME:
			handle_welcome(message)
		elif message["type"] == Enums.MessageType.JOIN_MESSAGE:
			handle_join_message(message)
		elif message["type"] == Enums.MessageType.CHAT_MESSAGE:
			handle_incoming_chat_message(message)
		elif message["type"] == Enums.MessageType.GAME_STATE:
			handle_incoming_game_state_message(message)
		elif message["type"] == Enums.MessageType.POSSIBLE_MOVES_REQUEST:
			handle_possible_moves(message)

func handle_player_exists(message: Dictionary):
	if message.has("value"):
		player_exists.emit(message["value"])

func handle_add_player(message: Dictionary):
	if not message.has("result"):
		return
	if message["result"] == Enums.AddPlayerResult.SUCCESS:
		hide_name_window.emit()
		show_chat_window.emit()
	if message.has("game_state"):
		new_game_state.emit(message["game_state"])

func handle_player_count_check(message: Dictionary):
	if not message.has("result"):
		return
	if message["result"] == Enums.PlayerCountResult.VALID:
		player_count_is_valid.emit(true)
	else:
		player_count_is_valid.emit(false)

func handle_welcome(message: Dictionary):
	if message.has("peer_id"):
		peer_id = int(message["peer_id"])
	else:
		printerr("no peer_id in response")

func handle_join_message(message: Dictionary):
	if message.has("peer_id") and message.has("player"):
		if message["player"].has("player_name") and message["player"].has("role"):
			var data := {}
			if message["peer_id"] == peer_id:
				data = { "player_name": "You", "role": message["player"]["role"] }
			else:
				data = { "player_name": message["player"]["player_name"], "role": message["player"]["role"] }
			send_join_message.emit(data)
			return
	printerr("join message object has missing information")

func handle_incoming_chat_message(message: Dictionary):
	if not message.has("message"):
		return
	if not message["message"].has("player_name") or not message["message"].has("text"):
		return
	send_chat_message.emit(message["message"])

func handle_incoming_game_state_message(message: Dictionary):
	if not message.has("move_type"):
		return
	if not message.has("move_data"):
		if message["move_type"] == Enums.MoveType.NONE:
			if message.has("new_state"):
				new_game_state.emit(message["new_state"])
		return
	# check game state with what was sent
	
	if message["move_type"] == Enums.MoveType.SLICE:
		if not message["move_data"].has("axis") or not message["move_data"].has("slice_index"):
			return
		var axis
		var slice_index :int = message["move_data"]["slice_index"]
		match message["move_data"]["axis"]:
			Enums.SliceAxis.X:
				axis = "x"
			Enums.SliceAxis.Y:
				axis = "y"
			Enums.SliceAxis.Z:
				axis = "z"
		var direction = message["move_data"]["direction"]
		slice_move.emit(axis, slice_index, direction)
	new_game_state.emit(message["new_state"])


func handle_possible_moves(message: Dictionary):
	if not message.has("data"):
		return
	# check for valid data
	possible_moves_received.emit(message["data"])
	awaiting_possible_moves = false


func on_player_submitted_button_pressed(player_name: String, role: Enums.PlayerRole):
	var request = { "type": Enums.MessageType.ADD_PLAYER, "player_name": player_name, "role": role }
	wsc.send(request)

func _on_websocket_server_server_listening(listening: Error):
	if listening == Error.OK:
		if url != "":
			connect_to_server()

func _on_panel_container_url_changed(new_url: String):
	url = new_url

func do_player_exist_request(name: String):
	if name == "":
		player_exists.emit(true)
		return
	var request = { "type": Enums.MessageType.PLAYER_EXISTS, "player_name": name }
	wsc.send(request)

func on_new_player_role_changed(role: Enums.PlayerRole):
	if role != Enums.PlayerRole.PLAYER:
		player_count_is_valid.emit(true)
		return
	var request = { "type": Enums.MessageType.PLAYER_COUNT_CHECK, "role": Enums.PlayerRole.PLAYER }
	wsc.send(request)

func on_chat_message_submitted(text: String):
	var data := { "type": Enums.MessageType.CHAT_MESSAGE, "text": text }
	wsc.send(data)

func on_cube_slice_turned(axis: String, slice_index: int, direction: int):
	var axis_as_enum
	match axis:
		"x":
			axis_as_enum = Enums.SliceAxis.X
		"y":
			axis_as_enum = Enums.SliceAxis.Y
		"z":
			axis_as_enum = Enums.SliceAxis.Z
	
	var data := {
		"type": Enums.MessageType.MOVE,
		"move_type": Enums.MoveType.SLICE,
		"move_data": {
			"axis": axis_as_enum,
			"slice_index": slice_index,
			"direction": direction
		}
	}
	wsc.send(data)

func request_possible_moves(tile):
	if awaiting_possible_moves:
		return
	awaiting_possible_moves = true
	var data := {
		"type": Enums.MessageType.POSSIBLE_MOVES_REQUEST,
		"data": {
			"face": tile.face,
			"board_position": "%s_%s" % [tile.board_position.x, tile.board_position.y]
		}
	}
	wsc.send(data)
