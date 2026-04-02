extends Control

@onready var inputed_name: LineEdit = $InputedName
@onready var connection: Label = $Connection
@onready var manager: Node = $"../.."

var server := TCPServer.new()
var clients = []

var user_input: String
var udp := PacketPeerUDP.new()
var is_hosting = false
var ip_client
enum NetState{
	DISCOVERY,
	CONNECTING,
	CONNECTED
}
var state = NetState.DISCOVERY
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	print(IP.get_local_addresses())
	server.listen(3000)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	var server_info = {
		"name": user_input,
		"port": 3000
	}
	
	if is_hosting:
		udp.put_packet(JSON.stringify(server_info).to_utf8_buffer())
		if udp.get_available_packet_count() > 0:
			var msg = udp.get_packet().get_string_from_utf8()
			ip_client = udp.get_packet_ip()
			is_hosting = false
			udp.close()
			print("Connecting:" ,ip_client)
			return
	if NetState.CONNECTED:
		if server.is_connection_available():
			var client = server.take_connection()
			print("Client connected from: ", client.get_connected_host())
			var packet = PacketPeerStream.new()
			packet.stream_peer = client
		
			clients.append(packet)
		
		for packet in clients:
			if packet.get_available_packet_count > 0:
				var data = packet.get_var()
				print("Received: ", data)

func _on_line_edit_text_submitted(new_text: String) -> void:
	user_input = inputed_name.text
	print("User entered: " + user_input)
	is_hosting = true
	setup_server()
	

func setup_server():
	udp.set_broadcast_enabled(true)
	udp.set_dest_address("255.255.255.255", 9999)

func on_connection():
	connection.text = "Connection Successfull!"
	manager.start_LAN_game()
	
