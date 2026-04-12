extends Control

var brodcastTimer : Timer
var broadcaster: PacketPeerUDP

var RoomInfo = {"name":"name","playerCount": 0}
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	brodcastTimer = $"Broadcast Timer"
	
func setUpBroadCast(name):
	pass # Replace with function body.
	#RoomInfo.name = name
	#RoomInfo.playerCount = GameManager.Players.size()
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
