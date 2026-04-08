extends Control
@onready var panel: Panel = $"../Panel"
@onready var host_menu: Control = $"../../Host Menu"

var client = StreamPeerTCP.new()
var clock = 0
var conFlag = false

var packet := PacketPeerStream.new()
var ip_old = {} 
var udp := PacketPeerUDP.new()

enum Status{
	DISCOVERY,
	CONNECTING,
	CONNECTED
}
var state = Status.DISCOVERY

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
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
				var buffer = StreamPeerBuffer.new()
				buffer.put_float(clock)
				client.put_data(buffer.data_array)
				if client.get_available_bytes() > 0:
					var data = client.get_utf8_string(client.get_available_bytes())
					print("Host: ", data)
			StreamPeerTCP.STATUS_ERROR:
				print("Connection Failed")
	if state == 2:
		pass
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

func _on_broadcast_timer_timeout() -> void:
	pass # Replace with function body.
