extends Node
@onready var timer_2: Timer = $Game/Ball/Timer2
@onready var left: StaticBody2D = $Game/Left
@onready var right: StaticBody2D = $Game/Right

var paddle_states = {}
var ball_data

func _ready():
	left.paddle_id = "Host"
	left.manager = self
	left.is_local = true #host paddle
	
	right.paddle_id = "Client"
	right.manager = self
	right.is_local = false #client
	
# UI functions
func start_local_game() -> void:
	get_node("Menu/Main").hide()
	get_node("Game").show()
	timer_2.start()

func view_multiplayer_menu() -> void:
	get_node("Menu/Main").hide()
	get_node("Menu/Multiplayer").show()

func browse_lobby_list() -> void:
	get_node("Menu/Multiplayer").hide()
	get_node("Menu/Join Menu").show()

func _on_sub_menu_join_back_pressed() -> void:
	get_node("Menu/Join Menu").hide()
	get_node("Menu/Main").show()

func _on_host_pressed() -> void:
	get_node("Menu/Multiplayer").hide()
	get_node("Menu/Host Menu").show()

func start_LAN_game():
	get_node("Menu/Host Menu").hide()
	get_node("Game").show()
	timer_2.start()
	

func _on_back_menu_pressed() -> void:
	get_node("Menu/Host Menu").hide()
	get_node("Menu/Main").show()

func pass_paddle_data(paddleID: String, y_position: float):
	paddle_states[paddleID] = y_position

func pass_ball_data(vel):
	ball_data = vel
	
func update_physics():
	return {
		"ball": ball_data, 
		"paddles": paddle_states
	}

func client_paddle(p):
	right.position = Vector2(0,p)
