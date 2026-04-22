extends Area2D

signal pointScored

@onready var timer = $Timer
@onready var ball: CharacterBody2D = $"../Ball"
@onready var left_lable: Label = $"../left_lable"

var score = 0

func _ready() -> void:
	connect("pointScored", get_parent().get_parent().ballBounced)

func _on_timer_timeout() -> void:
	Engine.time_scale = 1.0
	ball.position = Vector2(576,324)
	if get_parent().get_parent().isHost:
		pointScored.emit(ball.velocity)

func _on_body_entered(body: Node2D) -> void:
	#Engine.time_scale = 0.5
	timer.start()
	if get_parent().get_parent().inLobby:
		return
	add_point()

func add_point():
	score += 1
	left_lable.text = str(score)
	if get_parent().get_parent().isHost:
		get_parent().get_parent().UDPPacketBroadcaster.put_packet(PackedByteArray([2, 1]))
		if score == 5:
			get_parent().get_parent().UDPPacketBroadcaster.put_packet(PackedByteArray([3, 1]))
			get_parent().get_parent().win_game(false)
