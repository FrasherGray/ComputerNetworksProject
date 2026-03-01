extends Node
var UDPPacketHandler: PacketPeerStream = PacketPeerStream.new()
@onready var timer_2: Timer = $Game/Ball/Timer2


# Multiplayer functions
func _process(delta: float) -> void:
	while UDPPacketHandler.get_available_packet_count() > 0:
		var packet = UDPPacketHandler.get_packet()
		if UDPPacketHandler.get_packet_error() != 0:
			#discard packet, it's bad/wrong
			continue
		match packet[0]:
			0: # other player moved paddle
				if multiplayer.get_unique_id() == 1: # other player's paddle is the right one
					get_node("Game/Right").global_position = Vector2(packet[1], packet[2])
				else:
					get_node("Game/Left").global_position = Vector2(packet[1], packet[2])
			1: # ball bounced
				pass

# UI 
func start_local_game() -> void:
	get_node("Menu/Main").hide()
	get_node("Game").show()
	timer_2.start()

func view_multiplayer_menu() -> void:
	get_node("Menu/Main").hide()
	get_node("Menu/Multiplayer").show()

func browse_lobby_list() -> void:
	get_node("Menu/Multiplayer").hide()
	get_node("Menu/LobbyList").show()
