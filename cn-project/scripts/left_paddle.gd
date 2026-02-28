extends CharacterBody2D


const SPEED = 300.0
const JUMP_VELOCITY = -400.0
var locked_x = 0

func _ready() -> void:
	locked_x = global_position.x

func _physics_process(delta: float) -> void:
	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var direction := Input.get_axis("w", "s")
	if direction:
		velocity.y = direction * SPEED
	else:
		velocity.y = move_toward(velocity.x, 0, SPEED)
		
	# Only correct if something moved it
	if global_position.x != locked_x:
		global_position.x = locked_x
		
	move_and_slide()
