extends Node

signal start_server_command_received(port: int)
#signal send_to_single_peer(peer_id: int, message: Variant)

## Websocket Server
@export var wss: WebSocketServer

var port: int
var players := { 197356: { "player_name": "Blara", "role": Enums.PlayerRole.SPECTATOR } }


func start_server():
	if port > 0:
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
