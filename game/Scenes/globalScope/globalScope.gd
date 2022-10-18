extends Node

onready var server_connection := $ServerConnection
onready var chat_box = $GUI/chatbox

func _ready():
	yield(request_authentication(), "completed")
	yield(connect_to_server(), "completed")
	yield(server_connection.join_chat_async(), "completed")

func request_authentication():
	var email: String = Save.game_data.username + "@mendax.com"
	var password: String = "something"
	
	var result: int = yield(server_connection.authenticate_async(email,password), "completed")
	if result == OK:
		print("Authenticated user %s successfully" % email)
	else:
		print("Could not authenticate user %s" % email)

func connect_to_server() -> void:
	var result: int = yield(server_connection.connect_to_server_async(), "completed")
	if result == OK:
		print("Connected to the server")
	elif ERR_CANT_CONNECT:
		print("Could not connect to server")
	else:
		print("Unexpected error received")


func _on_ServerConnection_chat_message_received(username, text):
	print("message received from %s" % username)
	chat_box.add_message(username,text)


func _on_chatbox_message_sent(msg):
	yield(server_connection.send_text_async(msg), "completed")
	print("sent message to server")
