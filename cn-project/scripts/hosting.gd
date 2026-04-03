extends Control

@onready var inputed_name: LineEdit = $InputedName
@onready var connection: Label = $Connection
@onready var manager: Node = $"../.."

#var server := TCPServer.new()
#var clients = []

var user_input: String
var udp := PacketPeerUDP.new()
var is_hosting
var ip_client

#var listen_udp = PacketPeerUDP.new()

enum NetState{
	DISCOVERY,
	CONNECTING,
	CONNECTED
}

var state = NetState.DISCOVERY


var timer = 0.0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	print(IP.get_local_addresses())
	#listen_udp.bind(3000)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	var server_info = {
		"id": "MY_GAME",
		"name": user_input,
		"port": 3000
	}
	
	if is_hosting:
		#timer += delta
		#if timer > .5:
			#timer = 0
		udp.put_packet(JSON.stringify(server_info).to_utf8_buffer())
		while udp.get_available_packet_count() > 0: #listen_udp
			##ip_client = listen_udp.get_packet_ip()
			#is_hosting = false
			#listen_udp.close()
			#print("Connecting:" ,ip_client)
			return
	#if NetState.CONNECTED:
		#if server.is_connection_available():
			#var client = server.take_connection()
			#print("Client connected from: ", client.get_connected_host())
			#var packet = PacketPeerStream.new()
			#packet.stream_peer = client
		
			#clients.append(packet)
		
		#for packet in clients:
			#if packet.get_available_packet_count > 0:
				#var data = packet.get_var()
				#print("Received: ", data)

func _on_line_edit_text_submitted(new_text: String) -> void:
	user_input = inputed_name.text
	print("User entered: " + user_input)
	setup_server()
	is_hosting = true
	

func setup_server():
	if udp.is_bound():
		udp.close()

	udp.bind(9999)
	udp.set_broadcast_enabled(true)
	udp.set_dest_address("172.20.255.255", 9999)

func on_connection():
	connection.text = "Connection Successfull!"
	manager.start_LAN_game()
	
