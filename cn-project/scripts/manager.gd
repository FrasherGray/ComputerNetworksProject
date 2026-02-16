extends Node

func start_local_game() -> void:
	get_node("Menu/Main").hide()
	get_node("Game").show()

func view_multiplayer_menu() -> void:
	get_node("Menu/Main").hide()
	get_node("Menu/Multiplayer").show()

func browse_lobby_list() -> void:
	get_node("Menu/Multiplayer").hide()
	get_node("Menu/LobbyList").show()
