extends PanelContainer

@export var submit_button: Button

var player_name: String
var player_role: Enums.PlayerRole
var player_name_valid: bool
var player_role_valid: bool
signal player_name_changed(new_name: String)
signal player_role_changed(new_role: Enums.PlayerRole)
signal sumbit_button_pressed(player_name: String, role: Enums.PlayerRole)

func _on_line_edit_text_changed(new_text: String):
	#if new_text.is_empty():
	#	submit_button.disabled = true
	submit_button.disabled = true
	player_name = new_text
	player_name_changed.emit(player_name)

func on_player_exists(exists: bool):
	player_name_valid = !exists
	evaluate_button()

func on_player_role_is_valid(valid: bool):
	player_role_valid = valid
	evaluate_button()

func evaluate_button():
	if player_name_valid and player_role_valid:
		submit_button.disabled = false
	else:
		submit_button.disabled = true

func hide_window():
	visible = false

func _ready():
	player_name_valid = false
	player_role_valid = false
	
	if Client.client_ref == null:
		return
	
	Client.client_ref.player_exists.connect(on_player_exists)
	Client.client_ref.player_count_is_valid.connect(on_player_role_is_valid)
	Client.client_ref.hide_name_window.connect(hide_window)
	
	player_name_changed.connect(Client.client_ref.do_player_exist_request)
	player_role_changed.connect(Client.client_ref.on_new_player_role_changed)
	sumbit_button_pressed.connect(Client.client_ref.on_player_submitted_button_pressed)


func _on_role_selector_item_selected(index):
	if index == 0:
		player_role_changed.emit(Enums.PlayerRole.PLAYER)
		player_role = Enums.PlayerRole.PLAYER
	elif index == 1:
		player_role_changed.emit(Enums.PlayerRole.SPECTATOR)
		player_role = Enums.PlayerRole.SPECTATOR


func _on_submit_button_pressed():
	sumbit_button_pressed.emit(player_name, player_role)
