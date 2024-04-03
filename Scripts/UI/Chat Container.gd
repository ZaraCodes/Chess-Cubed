extends PanelContainer

var chat_message_packed = preload("res://Scenes/ChatMessage.tscn")

signal chat_message_submitted(data: Dictionary)

func _ready():
	if Client.client_ref == null:
		return
	Client.client_ref.show_chat_window.connect(show_chat_window)
	Client.client_ref.send_join_message.connect(add_join_message)
	chat_message_submitted.connect(Client.client_ref.on_chat_message_submitted)
	Client.client_ref.send_chat_message.connect(add_chat_message)

func show_chat_window():
	show()

func add_join_message(data: Dictionary):
	var chat_message = chat_message_packed.instantiate()
	chat_message.set_join_message(data["player_name"], data["role"])
	$"MarginContainer/VBoxContainer/ScrollContainer/Chat Messages".add_child(chat_message)

func add_chat_message(data: Dictionary):
	var chat_message = chat_message_packed.instantiate()
	chat_message.set_message(data["text"], data["player_name"])
	$"MarginContainer/VBoxContainer/ScrollContainer/Chat Messages".add_child(chat_message)


func _on_line_edit_text_submitted(new_text):
	chat_message_submitted.emit(new_text)
	$MarginContainer/VBoxContainer/LineEdit.text = ""
