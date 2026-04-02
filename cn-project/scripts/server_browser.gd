extends Control
@onready var panel: Panel = $"../Panel"

# var tcp := StreamPeerTCP.new()
var packet := PacketPeerStream.new()
var ip_old = {} 
var udp := PacketPeerUDP.new()

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	udp.bind(9999)
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	#if tcp.get_available_bytes() > 0:
	#	pass
	while udp.get_available_packet_count() > 0:
		var packet = udp.get_packet()
		var msg = packet.get_string_from_utf8()
		var ip = udp.get_packet_ip()
		var port = udp.get_packet_port()
		
		var data = JSON.parse_string(msg)
		if typeof(data) != TYPE_DICTIONARY:
			print("Invalid JSON from: ", ip)
			continue
		
		if not data.has("name") or not data.has("port"):
			print("Missing fields from:", ip)
			continue
		
		var key = ip + ":" + str(port) + data.name
		
		if not ip_old.has(key):
			print("Found sever at:",data.name, ip, data.port)
			panel.add_row(data.name,ip,data.port)
			ip_old[key] = true

func connect_to_server(ip: String, port: int):
	udp.set_dest_address(ip,port)
	var message = {
		"type": "join"
	}
	
	udp.put_packet(JSON.stringify(message).to_utf8_buffer())
	
	#tcp.connect_to_host(ip,port)
	#packet.stream_peer = tcp

func send_message(msg: String):
	pass
	#packet.put_utf8_string(msg)

func _on_broadcast_timer_timeout() -> void:
	pass # Replace with function body.
