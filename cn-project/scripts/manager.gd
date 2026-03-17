extends Node
@onready var timer_2: Timer = $Game/Ball/Timer2

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
