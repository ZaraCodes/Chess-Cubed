extends HBoxContainer


func update_ui_elements(axis: String, slice_index: int, direction: int):
	$SpinBox.value = slice_index
	match axis:
		"x":
			$OptionButton.selected = 0
		"y":
			$OptionButton.selected = 1
		"z":
			$OptionButton.selected = 2
	if direction == 1:
		$CheckBox.button_pressed = true
	else:
		$CheckBox.button_pressed = false

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
