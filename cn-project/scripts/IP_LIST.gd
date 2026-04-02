extends Panel
@onready var join_menu: Control = $".."
@onready var server_info: VBoxContainer = $ServerInfo
@onready var server_browser: Control = $"../Server Browser"

var Headers_IP_INFO = ["Name","IP Address", "Port", "Join"]
var IP_INFO = []
var header_info = false
var ip_host
var port_host 
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	join_menu.visibility_changed.connect(on_vis_changed)
	clear_table()
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func on_vis_changed():
	if not join_menu.visible:
		return
		
	print("Menu visible:", join_menu.visible)
	
	if not header_info:
		create_headers()
		header_info = true
		


func create_headers():
	var header_row = HBoxContainer.new()
	
	for header in Headers_IP_INFO:
		var column = CenterContainer.new()
		column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var label = Label.new()
		label.text = header
		column.add_child(label)
		header_row.add_child(column)
		
	server_info.add_child(header_row)
	print("Headers added")

func create_row(row):
	var row_container = HBoxContainer.new()
	for header in Headers_IP_INFO:
		var column = CenterContainer.new()
		column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		#add button to column to join
		if header == "Join":
			var join_button = Button.new()
			join_button.text = "Join"
			#connect IP signature to button press
			join_button.pressed.connect(_on_join_pressed.bind(row))
			column.add_child(join_button)
		else:
			var label = Label.new()
			label.text = str(row[header])
			column.add_child(label)
			
		row_container.add_child(column)
			
	server_info.add_child(row_container)
	print("Row added:", row["Name"])

func add_row(name, ip, port):
	if not join_menu.visible:
		return
	ip_host = ip
	port_host = port
	var new_row = {"Name":name,"IP Address":ip, "Port": port}
	IP_INFO.append(new_row)
	create_row(new_row)

func clear_table():
	var children = server_info.get_children()
	for i in range(1, children.size()):
		children[i].queue_free()

func _on_join_pressed(row):
	print("Joining server:")
	print("Name:", row["Name"])
	print("IP:", row["IP Address"])
	print("Port:", row["Port"])
	server_browser.connect_to_server(ip_host, port_host)
