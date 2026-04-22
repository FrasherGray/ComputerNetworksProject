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

var listen_udp = PacketPeerUDP.new()

enum NetState{
	DISCOVERY,
	CONNECTING,
	CONNECTED
}

var avg_latency := 0.0
const SMOOTHING = 0.5

var state = NetState.DISCOVERY

var timer = 0.0
const SEND_RATE = 1.0 / 30.0  # 20 snapshots per second 
var client_recv_buf = ""      # accumulates raw TCP bytes until a full \n-delimited message arrives

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	print(IP.get_local_addresses())

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	var server_info = {
		"id": "MY_GAME",
		"name": user_input,
		"port": 3001
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
			ip_client = udp.get_packet_ip()
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
			on_connection()
			
	if state == 2:
		timer += delta
		for peer in clients:
			# Accumulate incoming bytes into buffer, parse every complete newline-delimited message.
			# Keep only the last one — earlier messages are stale paddle positions.
			if peer.get_available_bytes() > 0:
				client_recv_buf += peer.get_utf8_string(peer.get_available_bytes())
			var last_paddle = null
			while "\n" in client_recv_buf:
				var idx = client_recv_buf.find("\n")
				var line = client_recv_buf.substr(0, idx)
				client_recv_buf = client_recv_buf.substr(idx + 1)
				if line.length() > 0:
					var json = JSON.new()
					if json.parse(line) == OK and json.data.has("py"):
						last_paddle = json.data
			if last_paddle:
				manager.client_paddle(float(last_paddle["py"]))
			
			# Send snapshot at a fixed rate to avoid flooding the TCP buffer
			if timer >= SEND_RATE:
				var packet = {
					"time": Time.get_unix_time_from_system(),
					"data": manager.update_physics()
				}
				peer.put_data((JSON.stringify(packet) + "\n").to_utf8_buffer())
				
		if timer >= SEND_RATE:
			timer = 0.0
				
func _on_line_edit_text_submitted(new_text: String) -> void:
	user_input = inputed_name.text
	print("User entered: " + user_input)
	setup_server()
	is_hosting = true
	
	
	
func _get_local_ip() -> String:
	for addr in IP.get_local_addresses():
		if addr.begins_with("192.") or addr.begins_with("10.") or addr.begins_with("172."):
			var parts := addr.split(".")
			if parts.size() == 4:
				# parts[2] = "255" 
				parts[3] = "255"
				return ".".join(parts)
	return "255.255.255.255"  # global broadcast fallback


func setup_server():
	if udp.is_bound():
		udp.close()

	var ipLocal = _get_local_ip()
	
	udp.bind(9999,"0.0.0.0")
	udp.set_broadcast_enabled(true)
	udp.set_dest_address(ipLocal, 9998)
	
	if not server.is_listening():
		var err = server.listen(3001, "0.0.0.0")
		if err != OK:
			print("TCP Server listen failed: ", err)

func on_connection():
	connection.text = "Connection Successfull!"
	manager.start_LAN_game()
	
