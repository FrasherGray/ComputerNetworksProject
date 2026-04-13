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
const SEND_RATE = 1.0 / 20.0  # 20 snapshots per second is plenty for LAN pong
var client_recv_buf = ""      # accumulates raw TCP bytes until a full \n-delimited message arrives
var seq: int = 0              # incremented with every snapshot sent; echoed by client for RTT
var rtt_log = []              # [{seq, rtt_ms}] round-trip times computed from client echo

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
					if json.parse(line) == OK and typeof(json.data) == TYPE_DICTIONARY:
						var d = json.data
						if d.has("type") and d["type"] == "report":
							_handle_client_report(d)
						elif d.has("py"):
							last_paddle = d
							if d.has("echo_ts"):
								var rtt = Time.get_ticks_msec() - int(d["echo_ts"])
								rtt_log.append({"seq": d.get("echo_seq", -1), "rtt_ms": rtt})
			if last_paddle:
				manager.client_paddle(float(last_paddle["py"]))
			
			# Send snapshot at a fixed rate; embed seq+ts so client can echo for RTT measurement
			if timer >= SEND_RATE:
				seq += 1
				var snapshot = manager.update_physics()
				snapshot["seq"] = seq
				snapshot["ts"] = Time.get_ticks_msec()
				peer.put_data((JSON.stringify(snapshot) + "\n").to_utf8_buffer())
		if timer >= SEND_RATE:
			timer = 0.0
				
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

func _handle_client_report(report: Dictionary) -> void:
	print("=== CLIENT LATENCY REPORT ===")
	var total_rtt = 0
	for entry in rtt_log:
		total_rtt += entry["rtt_ms"]
	var avg_rtt = (total_rtt / rtt_log.size()) if rtt_log.size() > 0 else 0
	print("Host RTT log — %d packets, avg %d ms" % [rtt_log.size(), avg_rtt])
	for entry in rtt_log:
		print("  seq=%-5d  rtt=%d ms" % [entry["seq"], entry["rtt_ms"]])
	if report.has("recv_log"):
		print("Client recv log — %d snapshots received" % report["recv_log"].size())
		for entry in report["recv_log"]:
			print("  seq=%-5d  host_ts=%-8d  client_recv_at=%d ms" % [entry["seq"], entry["host_ts"], entry["recv_ms"]])
	if report.has("send_log"):
		print("Client send log — %d paddle packets sent" % report["send_log"].size())
		for entry in report["send_log"]:
			print("  send_at=%-8d ms  py=%.1f" % [entry["send_ms"], entry["py"]])
	print("=== END REPORT ===")
	
