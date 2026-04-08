extends Control

@onready var inputed_name: LineEdit = $InputedName
@onready var connection: Label = $Connection
@onready var manager: Node = $"../.."

var server := TCPServer.new()
var port = 3000

var clients = []

var user_input: String
var udp := PacketPeerUDP.new()
var is_hosting = false
var ip_client

var listen_udp = PacketPeerUDP.new()

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
	listen_udp.bind(9999)
	
	var err = server.listen(3000, "0.0.0.0")
	if err != OK:
		print("Server Failed")
		return

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
			var packet = udp.get_packet()
			var msg = packet.get_string_from_utf8()
			var ip = udp.get_packet_ip()
			var port = udp.get_packet_port()
			
			if not (ip == "26.72.230.48"):
				print("GOT OWN PACKET")
				#continue
				
			var data = JSON.parse_string(msg)
			
			if not data.has("type"):
				print("Data has incorrect type")
				continue
			ip_client = listen_udp.get_packet_ip()
			is_hosting = false
			listen_udp.close()
			udp.close()
			
			
			print("TCP Starting")
		
			state = NetState.CONNECTING
			return
			
	if state == 1:
		if server.is_connection_available():
			var peer = server.take_connection()
			clients.append(peer)
			print("Connecting:" ,ip_client)
			print("CLIENT connected")
			state = NetState.CONNECTED
			
	if state == 2:
		for peer in clients:
			if peer.get_available_bytes() > 0:
				var data = peer.get_available_bytes()
				print("Recived: ", data)
			
			server.put_data(manager.update_physics())
				
func _on_line_edit_text_submitted(new_text: String) -> void:
	user_input = inputed_name.text
	print("User entered: " + user_input)
	setup_server()
	is_hosting = true
	

func setup_server():
	if udp.is_bound():
		udp.close()

	udp.bind(9999,"0.0.0.0")
	udp.set_broadcast_enabled(true)
	udp.set_dest_address("26.20.185.15", 9998)

func on_connection():
	connection.text = "Connection Successfull!"
	manager.start_LAN_game()
	
