extends StaticBody2D
class_name Paddle

# default values; ideally should not be relied upon
var upInput: String = "w"
var downInput: String = "s"

func _physics_process(delta: float) -> void:
	if not is_multiplayer_authority():
		return

	if Input.is_action_pressed(upInput) and global_position.y > 0:
		global_position.y -= 150 * delta
	elif Input.is_action_pressed(downInput) and global_position.y < 548:
		global_position.y += 150 * delta

func set_color(newColor: Color) -> void:
	if has_node("Box"):
		get_node("Box").set_color(newColor)
