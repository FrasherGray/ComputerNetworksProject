extends CharacterBody2D

func _ready() -> void:
	velocity = Vector2(200, 200)

func _physics_process(delta: float) -> void:
	var collision = move_and_collide(velocity * delta)
	
	if collision == null and not (global_position.y < 0 or global_position.y > 623):
		return
	
	if is_multiplayer_authority():
		if collision == null:
			velocity.y = -velocity.y
		else:
			velocity = (-velocity + Vector2(randi_range(-5, 5), randi_range(-5, 5))).normalized() * 200
		set_new_velocity.rpc(velocity)

@rpc("authority", "call_remote", "reliable")
func set_new_velocity(new_velocity: Vector2) -> void:
	velocity = new_velocity
