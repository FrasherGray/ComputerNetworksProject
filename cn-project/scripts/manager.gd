extends Node
@onready var timer_2: Timer = $Game/Ball/Timer2
@onready var left: StaticBody2D = $Game/Left
@onready var right: StaticBody2D = $Game/Right
@onready var ball_node: CharacterBody2D = $Game/Ball
@onready var server_browser: Control = $"Menu/Join Menu/Server Browser"
@onready var host_menu: Control = $"Menu/Host Menu"

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
		"ball": {
			"px": ball_node.global_position.x,
			"py": ball_node.global_position.y,
			"vx": ball_data.x if ball_data else 0.0,
			"vy": ball_data.y if ball_data else 0.0
		},
		"paddles": paddle_states
	}

# Called by host networking: stores received client paddle Y so right paddle's
# _process_netwrok() can pick it up on the next physics frame.
func client_paddle(p: float):
	paddle_states["Client"] = p

# Called by client networking: applies the host's authoritative game state.
func apply_game_state(snapshot: Dictionary):
	if snapshot.has("ball"):
		var bd = snapshot["ball"]
		ball_node.global_position = Vector2(float(bd["px"]), float(bd["py"]))
		ball_node.velocity = Vector2(float(bd["vx"]), float(bd["vy"]))
	if snapshot.has("paddles") and snapshot["paddles"].has("Host"):
		paddle_states["Host"] = float(snapshot["paddles"]["Host"])

# Called when this machine joins as a client.
# Flips paddle ownership: right = local (client controls it),
# left = network-driven (host position arrives via apply_game_state).
func start_client_game():
	left.is_local = false
	right.is_local = true
	ball_node.set_physics_process(false) # host is authoritative; client just renders
	get_node("Menu/Join Menu").hide()
	get_node("Game").show()

func game_over(winner: String):
	# Stop the ball so no more points can be scored
	ball_node.set_physics_process(false)
	ball_node.velocity = Vector2.ZERO
	# Show result then return to main menu
	get_node("Game").hide()
	var main = get_node("Menu/Main")
	main.show()
	#var Host = hosting.avg_latency
	var Client = server_browser.avg_latency
	print("Client Latency:", Client, "MS")
