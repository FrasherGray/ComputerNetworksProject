extends Control
@onready var panel: Panel = $"../Panel"
@onready var host_menu: Control = $"../../Host Menu"
@onready var manager: Node = $"../../.."
@onready var latencyNode: Label = $"../../../Game/latency"

var IPAddress: String

var client = StreamPeerTCP.new()
var clock = 0
var conFlag = false

var packet := PacketPeerStream.new()
var ip_old = {}
var udp := PacketPeerUDP.new()
var host_recv_buf = ""       # accumulates TCP bytes until a full \n-delimited snapshot arrives
var send_timer = 0.0
const SEND_RATE = 1.0 / 30.0  # send paddle at 20 Hz — matches host snapshot rate

var avg_latency := 0.0
const SMOOTHING = 0.5

enum Status{
	DISCOVERY,
	CONNECTING,
	CONNECTED
}
var state = Status.DISCOVERY

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if OS.has_feature("windows"):
		IPAddress = IP.get_local_addresses()[5]
	else:
		IPAddress = IP.get_local_addresses()[0]
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	clock = delta

	if not host_menu.is_hosting and state == 0:
		if not udp.is_bound():
			udp.bind(9998, "0.0.0.0")
		while udp.get_available_packet_count() > 0:
			var packet = udp.get_packet()
			if packet.size() == 0:
				continue
		
			var msg = packet.get_string_from_utf8()
			var ip = udp.get_packet_ip()
			var port = udp.get_packet_port()
		
			var data = JSON.parse_string(msg)
		
			if typeof(data) != TYPE_DICTIONARY:
				print("Invalid JSON from: ", ip)
				continue
		
			if not data.has("id") or data["id"] != "MY_GAME":
				continue
			
			if not data.has("name") or not data.has("port"):
				print("Missing fields from:", ip)
				continue
				
			var key = ip
			
			if panel.vis == true:
				if (ip_old.has(key)):
					continue
					
				ip_old[key] = true
				print("Found sever at:",data.name, ip, data.port)
				panel.add_row(data.name,ip,data.port)
				
	if state == 1:
		if client: 
			client.poll()
		
		match client.get_status():
			StreamPeerTCP.STATUS_CONNECTING:
				
				print("Connecting")
			StreamPeerTCP.STATUS_CONNECTED:
				state = Status.CONNECTED
				manager.start_client_game()
			StreamPeerTCP.STATUS_ERROR:
				print("Connection Failed")
	if state == 2:
		client.poll()
		if client.get_status() != StreamPeerTCP.STATUS_CONNECTED:
			print("Disconnected from host")
			state = Status.DISCOVERY
			return
		# Accumulate incoming bytes; snapshots from host are \n-terminated
		if client.get_available_bytes() > 0:
			host_recv_buf += client.get_utf8_string(client.get_available_bytes())
		# Drain all complete messages, keep only the latest to skip stale frames
		var last_snapshot = null
		while "\n" in host_recv_buf:
			var idx = host_recv_buf.find("\n")
			var line = host_recv_buf.substr(0, idx)
			host_recv_buf = host_recv_buf.substr(idx + 1)
			if line.length() > 0:
				var json = JSON.new()
				if json.parse(line) == OK and typeof(json.data) == TYPE_DICTIONARY:
					var packet = json.data
					if packet.has("time") and packet.has("data"):
						var sent_time = packet["time"]
						last_snapshot = packet["data"]
						
						var recv_time = Time.get_unix_time_from_system()
						var latency = recv_time - int(sent_time)
						
						avg_latency = lerp(avg_latency, float(latency), SMOOTHING)
						latencyNode.text = "Latency: " + str(latency) + "ms"
						
			if last_snapshot:
				manager.apply_game_state(last_snapshot)
		# Rate-limited paddle send — must include \n so host buffer can split correctly
		send_timer += delta
		if send_timer >= SEND_RATE:
			send_timer = 0.0
			if manager.paddle_states.has("Client"):
				var out = JSON.stringify({"py": manager.paddle_states["Client"]}) + "\n"
				client.put_data(out.to_utf8_buffer())
func connect_to_server(ip: String, port: int):
	
	udp.set_broadcast_enabled(true)
	udp.set_dest_address(ip,9999)
	var message = {
		"type": "CLIENT"
	}
	print("Joining Server", ip, port)
	udp.put_packet(JSON.stringify(message).to_utf8_buffer())
	
	udp.close()
	
	var err = client.connect_to_host(ip, int(port))
	if err != OK:
		print("Connection Failed")
	state = 1

func close_client() -> void:
	client.disconnect_from_host()
	host_recv_buf = ""
	send_timer = 0.0
	ip_old.clear()
	state = Status.DISCOVERY

func send_message(msg: String):
	pass
	#packet.put_utf8_string(msg)

func _on_broadcast_timer_timeout() -> void:
	pass # Replace with function body.
