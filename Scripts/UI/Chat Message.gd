extends RichTextLabel


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

func set_message(text: String, player_name: String):
	var chat_line = "[color=LIGHT_GRAY][%s] [color=gray]%s" % [escape_bbcode(player_name), escape_bbcode(text)]
	set_text(chat_line)

func set_join_message(player_name: String, role: Enums.PlayerRole):
	var role_string: String
	if role == Enums.PlayerRole.PLAYER:
		role_string = "[color=LAVENDER_BLUSH]player"
	elif role == Enums.PlayerRole.SPECTATOR:
		role_string = "[color=POWDER_BLUE]spectator"
	set_text("[i][color=LIGHT_GRAY]%s joined as %s" % [escape_bbcode(player_name), role_string])

func escape_bbcode(text: String):
	var regex = RegEx.new()
	regex.compile("\\[.*?\\]")
	return regex.sub(text, "", true)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
