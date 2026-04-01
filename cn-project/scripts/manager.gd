extends Node

# Port Definitions
const LOBBY_BROADCAST_PORT: int = 9821
const LOBBY_RECEIVER_PORT: int = 9921
const GAME_BROADCAST_PORT: int = 9822
const GAME_RECEIVER_PORT: int = 9922

# Host Variables
var isHost: bool = false
var clientIP: String = ""

# Client Variables
var inLobby: bool = false
var hostIP: String = ""

# General Multiplayer Variables
var IPAddress: String
var lobbyName: String = ""
var inMenu: bool = false

# Musc Var Declarations
var UDPPacketBroadcaster: PacketPeerUDP
var UDPPackedReceiver: PacketPeerUDP = PacketPeerUDP.new()
@onready var timer_2: Timer = $Game/Ball/Timer2


# Multiplayer functions
func _ready() -> void:
	if OS.has_feature("windows"):
		IPAddress = IP.get_local_addresses()[5]
	else:
		IPAddress = IP.get_local_addresses()[0]
	if UDPPackedReceiver.bind(LOBBY_RECEIVER_PORT) == OK:
		print("Receiver successfully set up")
	else:
		print("Receiver failed to bind to receiver port")

func _process(_delta: float) -> void:
	if UDPPackedReceiver == null:
		return

	while UDPPackedReceiver.get_available_packet_count() > 0:
		var packet = UDPPackedReceiver.get_packet()
		print(packet)
		if UDPPackedReceiver.get_packet_error() != 0:
			#discard packet, it's bad/wrong
			continue
		if inMenu:
			if isHost:
				if packet[0] == 1:
					sendHostData(UDPPackedReceiver.get_packet_ip())
			else:
				if inLobby:
					if packet[0] == 0: # host closed lobby
						# close game ui menu, when made
						get_node("Menu/Join Menu").show()
				else:
					var packetData: Dictionary = JSON.parse_string(packet.get_string_from_ascii())
					get_node("Menu/Join Menu/Panel").add_row(packetData["Name"], packetData["IP"], 1)
		match packet[0]:
			0: # other player moved paddle
				if multiplayer.get_unique_id() == 1: # other player's paddle is the right one
					get_node("Game/Right").global_position = Vector2(packet[1], packet[2])
				else:
					get_node("Game/Left").global_position = Vector2(packet[1], packet[2])
			1: # ball bounced
				pass

func setupHost() -> bool:
	UDPPacketBroadcaster = PacketPeerUDP.new()

	if UDPPacketBroadcaster.bind(LOBBY_BROADCAST_PORT) == OK:
		print("UDP bound successfully")
		return true
	else:
		print("UDP failed to bind to receiver port")
		return false

func setupClient() -> bool:
	UDPPacketBroadcaster = PacketPeerUDP.new()
	UDPPacketBroadcaster.set_broadcast_enabled(true)
	UDPPacketBroadcaster.set_dest_address("192.168.1.255", LOBBY_RECEIVER_PORT)
	
	if UDPPacketBroadcaster.bind(LOBBY_BROADCAST_PORT) == OK:
		print("UDP bound successfully")
		return true
	else:
		print("UDP failed to bind to receiver port")
		return false

func sendHostData(toIP: String) -> void:
	if not isHost or UDPPacketBroadcaster == null:
		return
	UDPPacketBroadcaster.set_dest_address(toIP, LOBBY_RECEIVER_PORT)
	var roomData: String = JSON.stringify({ "Name": lobbyName, "IP": IPAddress })
	UDPPacketBroadcaster.put_packet(roomData.to_ascii_buffer())

func requestLobbyData() -> void:
	for child in get_node("Menu/Join Menu/Panel/ServerInfo").get_children():
		child.queue_free()
	UDPPacketBroadcaster.put_packet(PackedByteArray([1]))

# UI 
func start_local_game() -> void:
	get_node("Menu/Main").hide()
	get_node("Game").show()
	timer_2.start()

func view_multiplayer_menu() -> void:
	get_node("Menu/Main").hide()
	get_node("Menu/Multiplayer").show()

func browse_lobby_list() -> void:
	var multiplayerWorks: bool = setupClient()
	if not multiplayerWorks:
		return
	requestLobbyData()
	get_node("Menu/Multiplayer").hide()
	get_node("Menu/Join Menu").show()

func join_lobby(ofIP: String) -> void:
	inLobby = true
	get_node("Menu/Join Menu").hide()

func _on_sub_menu_join_back_pressed() -> void:
	get_node("Menu/Join Menu").hide()
	get_node("Menu/Main").show()

func _on_host_pressed() -> void:
	var multiplayerWorks: bool = setupHost()
	if not multiplayerWorks:
		return
	get_node("Menu/Multiplayer").hide()
	get_node("Menu/Host Menu").show()

func create_host_lobby() -> void:
	lobbyName = get_node("Menu/Host Menu/InputedName").get_text()
	isHost = true

func start_LAN_game():
	get_node("Menu/Host Menu").hide()
	get_node("Game").show()
	timer_2.start()

func _on_back_menu_pressed() -> void:
	get_node("Menu/Host Menu").hide()
	get_node("Menu/Main").show()
