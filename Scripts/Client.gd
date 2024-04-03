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

static var client_ref: Client
var peer_id: int

## Websocket Client
@export var wsc: WebSocketClient


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
		if message["type"] == Enums.MessageType.ADD_PLAYER:
			handle_add_player(message)
		if message["type"] == Enums.MessageType.PLAYER_COUNT_CHECK:
			handle_player_count_check(message)
		if message["type"] == Enums.MessageType.WELCOME:
			handle_welcome(message)
		if message["type"] == Enums.MessageType.JOIN_MESSAGE:
			handle_join_message(message)
		if message["type"] == Enums.MessageType.CHAT_MESSAGE:
			handle_incoming_chat_message(message)

func handle_player_exists(message: Dictionary):
	if message.has("value"):
		player_exists.emit(message["value"])

func handle_add_player(message: Dictionary):
	if not message.has("result"):
		return
	if message["result"] == Enums.AddPlayerResult.SUCCESS:
		hide_name_window.emit()
		show_chat_window.emit()

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
