extends Control

@onready var inputed_name: LineEdit = $InputedName
@onready var connection: Label = $Connection
@onready var manager: Node = $"../.."

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_line_edit_text_submitted(new_text: String) -> void:
	var user_input: String = inputed_name.text
	print("User entered: " + user_input)
	# on_connection()

func on_connection():
	connection.text = "Connection Successfull!"
	manager.start_LAN_game()
	
