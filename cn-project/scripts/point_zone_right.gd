extends Area2D

@onready var timer = $Timer
@onready var ball: CharacterBody2D = $"../Ball"
@onready var right: StaticBody2D = $"../Right"
@onready var left: StaticBody2D = $"../Left"
@onready var left_lable: Label = $"../left_lable"

var score = 0

func _on_timer_timeout() -> void:
	Engine.time_scale = 1.0
	ball.position = Vector2(576,324)
	right.position = Vector2(1122,0)
	left.position = Vector2(0,0)

func _on_body_entered(body: Node2D) -> void:
	Engine.time_scale = 0.5
	add_point()
	timer.start()

func add_point():
	score += 1
	left_lable.text = str(score)
