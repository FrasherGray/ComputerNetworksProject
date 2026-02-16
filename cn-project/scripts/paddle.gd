extends StaticBody2D
class_name Paddle

# default values; ideally should not be relied upon
var upInput: String = "w"
var downInput: String = "s"

func _input(event: InputEvent) -> void:
	if event.is_action_pressed(upInput):
		# move up
		pass
	elif event.is_action_pressed(downInput):
		# move down
		pass

func set_color(newColor: Color) -> void:
	if has_node("Box"):
		get_node("Box").set_color(newColor)
