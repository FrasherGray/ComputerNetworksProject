extends StaticBody2D
class_name Paddle

const SPEED: int = 300

# default values; ideally should not be relied upon
var upInput: String = "w"
var downInput: String = "s"

var paddle_id: String = "" 
var manager: Node = null

func _ready():
	pass

func _physics_process(delta: float) -> void:

	
	if not is_multiplayer_authority():
		return

	if Input.is_action_pressed(upInput) and global_position.y > 0:
		global_position.y -= SPEED * delta
	elif Input.is_action_pressed(downInput) and global_position.y < 548:
		global_position.y += SPEED * delta
	if manager:
		manager.pass_paddle_data(paddle_id, global_position.y)

func set_color(newColor: Color) -> void:
	if has_node("Box"):
		get_node("Box").set_color(newColor)
