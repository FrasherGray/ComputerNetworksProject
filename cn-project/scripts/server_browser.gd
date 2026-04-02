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
	if udp.get_available_packet_count() > 0:
		var msg = udp.get_packet().get_string_from_utf8()
		var ip = udp.get_packet_ip()
		var data = JSON.parse_string(msg)
		
		if not ip_old.has(ip):
			print("Found sever at:",data.name, ip, data.port)
			panel.add_row(data.name,ip,data.port)
			ip_old[ip] = true

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
