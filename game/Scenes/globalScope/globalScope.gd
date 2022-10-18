extends Node

onready var server_connection := $ServerConnection
onready var chat_box = $GUI/chatbox

"""
/*
* @pre called once when scene is called
* @post authenticates, connects to server, and joins general chat
* @param None
* @return None
*/
"""
func _ready():
	yield(request_authentication(), "completed")
	yield(connect_to_server(), "completed")
	yield(server_connection.join_chat_async_general(), "completed")

"""
/*
* @pre called in _ready
* @post calls authentication function
* @param None
* @return None
*/
"""
func request_authentication():
	var user: String = Save.game_data.username
	
	var result: int = yield(server_connection.authenticate_async(), "completed")
	if result == OK:
		print("Authenticated user %s successfully" % user)
	else:
		print("Could not authenticate user %s" % user)

"""
/*
* @pre called once in _ready
* @post calls connection to server function
* @param None
* @return None
*/
"""
func connect_to_server() -> void:
	var result: int = yield(server_connection.connect_to_server_async(), "completed")
	if result == OK:
		print("Connected to the server")
	elif ERR_CANT_CONNECT:
		print("Could not connect to server")
	else:
		print("Unexpected error received")

"""
/*
* @pre called once to authenticate user
* @post connects to the server
* @param username -> String, text -> String
* @return None
*/
"""
func _on_ServerConnection_chat_message_received(username, text):
	print("message received from %s" % username)
	chat_box.add_message(username,text)

"""
/*
* @pre called when user submits message to chatbox
* @post sends message to send_text_async function
* @param msg -> String
* @return None
*/
"""
func _on_chatbox_message_sent(msg):
	yield(server_connection.send_text_async(msg), "completed")
	print("sent message to server")
