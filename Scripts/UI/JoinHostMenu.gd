class_name Server
extends Node


var port: int
var url: String

signal join_button_pressed()
signal host_button_pressed()
signal port_changed(new_port: int)
signal url_changed(new_url: String)

func _on_port_edit_text_changed(new_text: String):
	var caret_pos := int($"VBoxContainer/HBoxContainer/Port Edit".caret_column)
	var new_port := new_text
	for char in new_text:
		if char not in "0123456789":
			new_port = new_text.replace(char, "")
			caret_pos -= 1
	
	$"VBoxContainer/HBoxContainer/Port Edit".text = new_port
	$"VBoxContainer/HBoxContainer/Port Edit".caret_column = caret_pos
	port = int(new_port)
	port_changed.emit(port)


func _on_url_edit_text_changed(new_text: String):
	url = new_text
	url_changed.emit(url)


func _on_host_button_pressed():
	if port != 0:
		host_button_pressed.emit()
	else:
		printerr("Port is 0")


func _on_join_button_pressed():
	if url != "":
		join_button_pressed.emit()
	else:
		printerr("URL is empty")

func _ready():
	$"VBoxContainer/HBoxContainer/Port Edit".text = "8002"
	$"VBoxContainer/HBoxContainer2/URL Edit".text = "ws://localhost:8002"
	_on_url_edit_text_changed($"VBoxContainer/HBoxContainer2/URL Edit".text)
	_on_port_edit_text_changed($"VBoxContainer/HBoxContainer/Port Edit".text)


func _on_client_connected_to_server():
	var packed_game_scene = preload("res://Scenes/GameScene.tscn")
	var scene_instance = packed_game_scene.instantiate()
	get_parent().add_child(scene_instance)
	queue_free()
