extends Node

# Port Definitions
const LOBBY_BROADCAST_PORT: int = 9821
const LOBBY_RECEIVER_PORT: int = 9921
const GAME_BROADCAST_PORT: int = 9822
const GAME_RECEIVER_PORT: int = 9922

# Host Variables
var isHost: bool = false
var clientIP: String = ""
var lobbyFull: bool = false

# Client Variables
var inLobby: bool = false
var hostIP: String = ""

# General Multiplayer Variables
var playerName: String = "John Doe"
var IPAddress: String
var lobbyName: String = ""
var inMenu: bool = true
var sentPositionTicker: int = 0

# Misc Var Declarations
var UDPPacketBroadcaster: PacketPeerUDP
var UDPPacketReceiver: PacketPeerUDP = PacketPeerUDP.new()
@onready var timer_2: Timer = $Game/Ball/Timer2


# Multiplayer functions
func _ready() -> void:
	if OS.has_feature("windows"):
		IPAddress = IP.get_local_addresses()[5]
	else:
		IPAddress = IP.get_local_addresses()[0]
	if UDPPacketReceiver.bind(LOBBY_RECEIVER_PORT) == OK:
		print("Receiver successfully set up")
	else:
		print("Receiver failed to bind to receiver port")
	
	if FileAccess.file_exists("user://settings"):
		var playerSettings = FileAccess.open("user://settings", FileAccess.READ)
		playerName = playerSettings.get_pascal_string()
	else:
		var playerSettings = FileAccess.open("user://settings", FileAccess.WRITE)
		playerSettings.store_pascal_string(playerName)
	get_node("Menu/Main/PlayerName").set_text(playerName)

func _process(_delta: float) -> void:
	if UDPPacketReceiver == null:
		return

	while UDPPacketReceiver.get_available_packet_count() > 0:
		var packet = UDPPacketReceiver.get_packet()
		print(packet)
		if UDPPacketReceiver.get_packet_error() != 0:
			#discard packet, it's bad/wrong
			continue
		print(inMenu, ", ", isHost, ", ", inLobby)
		if inMenu:
			if isHost:
				if packet[0] == 1 and not lobbyFull:
					sendHostData(UDPPacketReceiver.get_packet_ip())
				elif packet[0] == 2:
					if lobbyFull:
						UDPPacketBroadcaster.set_dest_address(UDPPacketReceiver.get_packet_ip(), LOBBY_RECEIVER_PORT)
						UDPPacketBroadcaster.put_packet(PackedByteArray([0]))
						UDPPacketBroadcaster.set_dest_address(clientIP, LOBBY_RECEIVER_PORT)
					else:
						lobbyFull = true
						get_node("Menu/Lobby Menu/Start").set_disabled(false)
						get_node("Menu/Lobby Menu/Player2").set_text(packet.get_string_from_ascii().right(-1))
						clientIP = UDPPacketReceiver.get_packet_ip()
						print("Client: ", clientIP)
					
					var namePacket: PackedByteArray = PackedByteArray([4])
					namePacket.append_array(playerName.to_ascii_buffer())
				elif packet[0] == 3:
					client_started_LAN_game(packet.decode_float(1))
				elif packet[0] == 5:
					var textMessage: String = packet.get_string_from_ascii().right(-1)
					get_node("Menu/Lobby Menu/Chat").addMessage(textMessage, get_node("Menu/Lobby Menu/Player2").get_text())
					UDPPacketBroadcaster.put_packet(PackedByteArray([6]))
				elif packet[0] == 6:
					get_node("Menu/Lobby Menu/Chat").addMessage(get_node("Menu/Lobby Menu/Chat").messageQueue[0], "")
					get_node("Menu/Lobby Menu/Chat").messageQueue.erase(0)
			else:
				if inLobby:
					if packet[0] == 0: # host closed lobby or rejected from lobby
						inLobby = false
						get_node("Menu/Lobby Menu").hide()
						get_node("Menu/Join Menu").show()
						requestLobbyData()
					elif packet[0] == 3: # host starting game
						print("I AM THE CLIENT")
						var newPacket: PackedByteArray = PackedByteArray([3, 0, 0, 0, 0])
						newPacket.encode_float(1, Time.get_unix_time_from_system())
						UDPPacketBroadcaster.put_packet(newPacket)
						get_node("Menu/Lobby Menu").hide()
						get_node("Game").show()
						get_node("Game/Left").locally_owned = false
						get_node("Game/Right").locally_owned = true
						timer_2.start()
						inMenu = false
						UDPPacketReceiver.close()
						if UDPPacketReceiver.bind(GAME_RECEIVER_PORT) == OK:
							print("Receiver set up for Game")
						else:
							print("Receiver failed to set up for Game")
						UDPPacketBroadcaster.close()
						UDPPacketBroadcaster.set_dest_address(hostIP, GAME_RECEIVER_PORT)
						if UDPPacketBroadcaster.bind(GAME_BROADCAST_PORT) == OK:
							print("Broadcaster set up for Game")
						else:
							print("Broadcaster failed to set up for Game")
					elif packet[0] == 4: # host sent you their name
						var hostName: String = packet.get_string_from_ascii().right(-1)
						get_node("Menu/Lobby Menu/Player1").set_text(hostName)
					elif packet[0] == 5:
						var textMessage: String = packet.get_string_from_ascii().right(-1)
						get_node("Menu/Lobby Menu/Chat").addMessage(textMessage, get_node("Menu/Lobby Menu/Player1").get_text())
						UDPPacketBroadcaster.put_packet(PackedByteArray([6]))
					elif packet[0] == 6:
						get_node("Menu/Lobby Menu/Chat").addMessage(get_node("Menu/Lobby Menu/Chat").messageQueue[0], "")
						get_node("Menu/Lobby Menu/Chat").messageQueue.erase(0)
				elif packet.size() > 1:
					var packetData: Dictionary = JSON.parse_string(packet.get_string_from_ascii())
					get_node("Menu/Join Menu/Panel").add_row(packetData["Lobby"], UDPPacketReceiver.get_packet_ip(), 1)
		else:
			match packet[0]:
				0: # other player moved paddle
					if isHost: # other player's paddle is the right one
						get_node("Game/Right").global_position.y = packet[1] * 255 + packet[2]
					else:
						get_node("Game/Left").global_position.y = packet[1] * 255 + packet[2]
				1: # ball bounced
					var timeSent: float = packet.decode_float(1)
					if Time.get_unix_time_from_system() - timeSent > 0.1:
						return
					var newVelocity: Vector2 = Vector2(packet[5] + packet[6], packet[7] + packet[8])
					var synchronizedPosition: Vector2 = Vector2(packet[9] * 255 + packet[10], packet[11] * 255 + packet[12])
					get_node("Game/Ball").velocity = newVelocity
					get_node("Game/Ball").set_global_position(synchronizedPosition)
				2: # host recorded a point
					match packet[1]:
						0:
							get_node("Game/Point Zone Left").add_point()
						1:
							get_node("Game/Point Zone Right").add_point()

func _physics_process(_delta: float) -> void:
	if inMenu:
		return

	if sentPositionTicker == 8:
		var packet: PackedByteArray
		var yValue: int
		if isHost:
			yValue = roundi(get_node("Game/Left").get_global_position().y)
		else:
			yValue = roundi(get_node("Game/Right").get_global_position().y)
		packet = PackedByteArray([0, yValue / 255, yValue % 255])
		UDPPacketBroadcaster.put_packet(packet)
		sentPositionTicker = 0
	else:
		sentPositionTicker += 1

func ballBounced(newVelocity: Vector2i) -> void:
	var velocityPacket: PackedByteArray = PackedByteArray([1, 0, 0, 0, 0])
	var currentTime: float = Time.get_unix_time_from_system()
	velocityPacket.encode_float(1, currentTime)
	
	if newVelocity.x > 255:
		velocityPacket.append_array([newVelocity.x - 255, 255])
	else:
		velocityPacket.append_array([0, newVelocity.x])
	if newVelocity.y > 255:
		velocityPacket.append_array([newVelocity.y - 255, 255])
	else:
		velocityPacket.append_array([0, newVelocity.y])
	var ballPosition: Vector2 = get_node("Game/Ball").get_global_position()
	velocityPacket.append_array([roundi(ballPosition.x / 255.0), int(ballPosition.x) % 255, roundi(ballPosition.y / 255.0), int(ballPosition.y) % 255])
	UDPPacketBroadcaster.put_packet(velocityPacket)

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
	UDPPacketBroadcaster.set_dest_address("255.255.255.255", LOBBY_RECEIVER_PORT)
	
	if UDPPacketBroadcaster.bind(LOBBY_BROADCAST_PORT) == OK:
		print("UDP bound successfully")
		return true
	else:
		print("UDP failed to bind to receiver port")
		return false

func sendHostData(toIP: String) -> void:
	print("sending host data")
	if not isHost or UDPPacketBroadcaster == null:
		return
	print("to ", toIP)
	UDPPacketBroadcaster.set_dest_address(toIP, LOBBY_RECEIVER_PORT)
	var roomData: String = JSON.stringify({ "Lobby": lobbyName, "Player": playerName })
	UDPPacketBroadcaster.put_packet(roomData.to_ascii_buffer())

func requestLobbyData() -> void:
	print("Requesting lobby data")
	for c in get_node("Menu/Join Menu/Panel/ServerInfo").get_child_count():
		if c == 0:
			continue
		get_node("Menu/Join Menu/Panel/ServerInfo").get_child(c).queue_free()
	UDPPacketBroadcaster.put_packet(PackedByteArray([1]))

func sendMessage(text: String) -> void:
	var message: PackedByteArray = PackedByteArray([5])
	message.append_array(text.to_ascii_buffer())
	UDPPacketBroadcaster.put_packet(message)

# UI 
func edit_player_name(newName: String) -> void:
	playerName = newName
	var playerSettings = FileAccess.open("user://settings", FileAccess.WRITE)
	playerSettings.store_pascal_string(playerName)

func start_local_game() -> void:
	get_node("Menu/Main").hide()
	get_node("Game").show()
	get_node("Game/Left").locally_owned = true
	get_node("Game/Right").locally_owned = true
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

func join_lobby(lobbyData: Dictionary) -> void:
	inLobby = true
	get_node("Menu/Join Menu").hide()
	
	hostIP = lobbyData["IP Address"]
	print("Host: ", hostIP)
	get_node("Menu/Lobby Menu/Name").set_text(lobbyData["Name"])
	get_node("Menu/Lobby Menu/Player1").set_text(hostIP)
	get_node("Menu/Lobby Menu/Player2").set_text(playerName)
	UDPPacketBroadcaster.set_dest_address(hostIP, LOBBY_RECEIVER_PORT)
	var joinRequestPacket: PackedByteArray = PackedByteArray([2])
	joinRequestPacket.append_array(playerName.to_ascii_buffer())
	UDPPacketBroadcaster.put_packet(joinRequestPacket)
	
	get_node("Menu/Lobby Menu").show()

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
	get_node("Menu/Host Menu").hide()
	get_node("Menu/Lobby Menu").show()
	get_node("Menu/Lobby Menu/Name").set_text(lobbyName)
	get_node("Menu/Lobby Menu/Player1").set_text(playerName)
	get_node("Menu/Lobby Menu/Player2").set_text("Empty")

func start_LAN_game():
	get_node("Menu/Lobby Menu/Start").set_disabled(true)
	UDPPacketBroadcaster.put_packet(PackedByteArray([3]))

func client_started_LAN_game(timeSinceConfirm: float) -> void:
	print("I AM THE HOST")
	get_node("Menu/Lobby Menu").hide()
	get_node("Game").show()
	get_node("Game/Left").locally_owned = true
	get_node("Game/Right").locally_owned = false
	timer_2.set_wait_time(3 - (Time.get_unix_time_from_system() - timeSinceConfirm))
	timer_2.start()
	inMenu = false
	UDPPacketReceiver.close()
	if UDPPacketReceiver.bind(GAME_RECEIVER_PORT) == OK:
		print("Receiver set up for Game")
	else:
		print("Receiver failed to set up for game")
	UDPPacketBroadcaster.close()
	UDPPacketBroadcaster.set_dest_address(clientIP, GAME_RECEIVER_PORT)
	if UDPPacketBroadcaster.bind(GAME_BROADCAST_PORT) == OK:
		print("Broadcaster set up for Game")
	else:
		print("Broadcaster failed to set up for game")

func _on_back_menu_pressed() -> void:
	get_node("Menu/Host Menu").hide()
	get_node("Menu/Main").show()

func leave_lobby_menu() -> void:
	get_node("Menu/Lobby Menu/Start").set_disabled(true)
	get_node("Menu/Lobby Menu").hide()
	get_node("Menu/Main").show()
	if lobbyFull:
		UDPPacketBroadcaster.put_packet(PackedByteArray([0]))
		lobbyFull = false
	isHost = false
