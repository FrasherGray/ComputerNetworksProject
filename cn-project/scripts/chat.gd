extends Control

@onready var manager = get_parent().get_parent().get_parent()

var lastMaxScroll: float = 0.0
var messageSentCounter: float = 0.0
var messageQueue: PackedStringArray = []

func _ready() -> void:
	get_node("Message").get_v_scroll_bar().connect("changed", addScroll)

func _process(delta: float) -> void:
	messageSentCounter += delta
	if messageQueue.size() != 0 and messageSentCounter > 0.2:
		messageSentCounter = 0.0
		var message: PackedByteArray = PackedByteArray([5])
		message.append_array(messageQueue[0].to_ascii_buffer())
		print(manager.UDPPacketBroadcaster.is_socket_connected())
		if manager.UDPPacketBroadcaster.is_socket_connected():
			manager.UDPPacketBroadcaster.put_packet(message)

func addMessage(text: String, sender: String) -> void:
	var message = Label.new()
	message.set_autowrap_mode(TextServer.AUTOWRAP_WORD)
	message.set_text(text)
	if sender == "":
		message.set_horizontal_alignment(HORIZONTAL_ALIGNMENT_RIGHT)
	else:
		message.set_horizontal_alignment(HORIZONTAL_ALIGNMENT_LEFT)
		message.set_text(message.get_text().insert(0, sender + ": "))
	message.connect("tree_entered", addScroll)
	get_node("Message/History").add_child(message)
	while get_node("Message/History").get_child_count() > 20:
		get_node("Message/History").get_child(0).queue_free()
		await get_tree().process_frame

func sendMessage(text: String) -> void:
	messageQueue.append(text)
	get_node("Text").set_text("")
	get_node("Text").release_focus()

func editMessage(text: String) -> void:
	if len(text) > 100:
		get_node("Text").set_self_modulate(Color.RED)
	else:
		get_node("Text").set_self_modulate(Color.WHITE)

func addScroll() -> void:
	if get_node("Message").get_v_scroll() == lastMaxScroll:
		get_node("Message").set_v_scroll(get_node("Message").get_v_scroll_bar().get_max())
	elif lastMaxScroll == 5:
		get_node("Message").set_v_scroll(5)
	lastMaxScroll = get_node("Message").get_v_scroll_bar().get_max() - 250
