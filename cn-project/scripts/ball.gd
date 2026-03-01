extends CharacterBody2D

var SPEED = 350
@onready var timer: Timer = $Timer
@onready var timer_2: Timer = $Timer2


func _ready():
	set_physics_process(false)
	randomize()
	
	# Pick a random angle increment of 45 degrees
	var angle = [1,4,7,11].pick_random() * 30
	
	#convert to red
	var rad = deg_to_rad(angle)
	var direction = Vector2(cos(rad), sin(rad))

	velocity = direction.normalized() * SPEED

func _physics_process(delta):
	var collision = move_and_collide(velocity * delta)
	if collision == null:
		return

	velocity = (velocity.bounce(collision.get_normal()) + Vector2(randf_range(-15, 15), randf_range(-15, 15))).normalized() * SPEED

func _on_timer_timeout():
	if(SPEED >= 500):
		SPEED = 500
	else:
		SPEED += 10
	velocity = velocity.normalized() * SPEED
	
func _on_timer_2_timeout():
	print("timer2")
	set_physics_process(true)
	$Timer.start()
