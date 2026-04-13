extends Control
@onready var panel: Panel = $"../Panel"
@onready var host_menu: Control = $"../../Host Menu"
@onready var manager: Node = $"../../.."

var IPAddress: String

var client = StreamPeerTCP.new()
var clock = 0
var conFlag = false

var packet := PacketPeerStream.new()
var ip_old = {}
var udp := PacketPeerUDP.new()
var host_recv_buf = ""       # accumulates TCP bytes until a full \n-delimited snapshot arrives
var send_timer = 0.0
const SEND_RATE = 1.0 / 20.0  # send paddle at 20 Hz — matches host snapshot rate
var game_start_ms: int = 0    # Time.get_ticks_msec() when game started; basis for all log timestamps
var recv_log = []             # [{seq, host_ts, recv_ms}] — one entry per received snapshot
var send_log = []             # [{send_ms, py}] — one entry per paddle packet sent
var last_echo_seq: int = -1   # seq from most recent snapshot; echoed in next paddle send
var last_echo_ts: int = -1    # ts from most recent snapshot; echoed so host can compute RTT

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
	udp.bind(9998,"0.0.0.0")
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	clock = delta
	#if tcp.get_available_bytes() > 0:
	#	pass
	if not host_menu.is_hosting and state == 0:
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
				game_start_ms = Time.get_ticks_msec()
				manager.start_client_game(self)
			StreamPeerTCP.STATUS_ERROR:
				print("Connection Failed")
	if state == 2:
		client.poll()
		# Accumulate incoming bytes; snapshots from host are \n-terminated
		if client.get_available_bytes() > 0:
			host_recv_buf += client.get_utf8_string(client.get_available_bytes())
		# Drain all complete messages; record each for logging, apply only the latest
		var last_snapshot = null
		while "\n" in host_recv_buf:
			var idx = host_recv_buf.find("\n")
			var line = host_recv_buf.substr(0, idx)
			host_recv_buf = host_recv_buf.substr(idx + 1)
			if line.length() > 0:
				var json = JSON.new()
				if json.parse(line) == OK and typeof(json.data) == TYPE_DICTIONARY:
					last_snapshot = json.data
		# Apply only the freshest snapshot — older ones in the buffer are stale
		if last_snapshot:
			var recv_ms = Time.get_ticks_msec() - game_start_ms
			if last_snapshot.has("seq"):
				recv_log.append({"seq": last_snapshot["seq"], "host_ts": last_snapshot.get("ts", 0), "recv_ms": recv_ms})
				last_echo_seq = last_snapshot["seq"]
				last_echo_ts = last_snapshot.get("ts", 0)
			manager.apply_game_state(last_snapshot)
		# Rate-limited paddle send — echo host's last seq+ts so it can measure RTT
		send_timer += delta
		if send_timer >= SEND_RATE:
			send_timer = 0.0
			if manager.paddle_states.has("Client"):
				var py = manager.paddle_states["Client"]
				var send_ms = Time.get_ticks_msec() - game_start_ms
				send_log.append({"send_ms": send_ms, "py": py})
				var out_data = {"py": py, "echo_seq": last_echo_seq, "echo_ts": last_echo_ts}
				client.put_data((JSON.stringify(out_data) + "\n").to_utf8_buffer())
func connect_to_server(ip: String, port: int):
	
	udp.set_broadcast_enabled(true)
	udp.set_dest_address(ip,9999)
	var message = {
		"type": "CLIENT"
	}
	print("Joining Server", ip, port)
	udp.put_packet(JSON.stringify(message).to_utf8_buffer())
	
	udp.close()
	
	var err = client.connect_to_host(ip, port)
	if err != OK:
		print("Connection Failed")
	state = 1

func send_message(msg: String):
	pass
	#packet.put_utf8_string(msg)

# Called by manager.game_over() — sends the full latency log to the host and saves a local copy.
func send_latency_report() -> void:
	var report = {
		"type": "report",
		"recv_log": recv_log,
		"send_log": send_log
	}
	client.put_data((JSON.stringify(report) + "\n").to_utf8_buffer())

	var lines = []
	lines.append("=== CLIENT LATENCY LOG ===")
	lines.append("Generated: %s" % Time.get_datetime_string_from_system())
	lines.append("")
	lines.append("RECV LOG — %d snapshots received" % recv_log.size())
	for entry in recv_log:
		lines.append("  seq=%-5d  host_ts=%-8d  recv_at=%d ms" % [entry["seq"], entry["host_ts"], entry["recv_ms"]])
	lines.append("")
	lines.append("SEND LOG — %d paddle packets sent" % send_log.size())
	for entry in send_log:
		lines.append("  send_at=%-8d ms  py=%.1f" % [entry["send_ms"], entry["py"]])
	lines.append("")
	lines.append("=== END LOG ===")

	var path = "user://client_latency_%s.txt" % Time.get_datetime_string_from_system().replace(":", "-")
	var f = FileAccess.open(path, FileAccess.WRITE)
	if f:
		f.store_string("\n".join(lines))
		f.close()
		print("Client latency log saved to: ", ProjectSettings.globalize_path(path))
	else:
		print("Failed to write client log: ", FileAccess.get_open_error())

func _on_broadcast_timer_timeout() -> void:
	pass # Replace with function body.
