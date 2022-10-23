extends Node

#Member Variables
onready var server_connection := $ServerConnection
onready var chat_box = $GUI/chatbox

#Scene Paths
var main_menu = "res://Scenes/mainMenu/mainMenu.tscn"
var market = "res://Scenes/StoreElements/StoreVars.tscn"
var start_area = "res://Scenes/startArea/startArea.tscn"
var cave = "res://Scenes/startArea/EntrySpace.tscn"
var riddler_minigame = "res://Scenes/minigames/riddler/riddleGame.tscn"

#Current scene running
var current_scene = null
#State to compare to the global state to see if anything changes
var local_state = null

"""
/*
* @pre called once when scene is called
* @post authenticates, connects to server, and joins general chat
* @param None
* @return None
*/
"""
func _ready():
	#Load initial scene (main menu)
	current_scene = load(main_menu).instance()
	add_child(current_scene)
	Global.state = Global.scenes.MAIN_MENU
	local_state = Global.scenes.MAIN_MENU
	#Connect to Server
	server_checks()

"""
/*
* @pre called for every frame in the game
* @post checks if state has changed, frees current scene and
* 	calls function to switch scenes if so
* @param _delta -> time thing
* @return None
*/
"""
func _process(_delta): #if you want to use _delta, remove _
	if local_state != Global.state:
		#free up memory
		current_scene.queue_free()
		#change the scene
		_change_scene_to(Global.state)

"""
/*
* @pre called when global wants to change scenes
* @post changes scene and adds it as a child to global scene
* @param state -> int
* @return None
*/
"""
func _change_scene_to(state):
	#Load the correct scene
	if state == Global.scenes.MAIN_MENU:
		current_scene = load(main_menu).instance()
	elif state == Global.scenes.MARKET:
		current_scene = load(market).instance()
	elif state == Global.scenes.START_AREA:
		current_scene = load(start_area).instance()
	elif state == Global.scenes.CAVE:
		current_scene = load(cave).instance()
	elif state == Global.scenes.RIDDLER_MINIGAME:
		current_scene = load(riddler_minigame).instance()
	#add scene to tree and revise local state
	add_child(current_scene)
	local_state = Global.state

"""
/*
* @pre called once in _ready function
* @post authenticates, connects to server, and joins general chat
* 	if there were no errors along the way
* @param None
* @return None
*/
"""
func server_checks():
	var result = yield(request_authentication(), "completed")
	if result == OK:
		result = yield(connect_to_server(), "completed")
		if result == OK:
			yield(server_connection.join_chat_async_general(), "completed")

"""
/*
* @pre called in _ready
* @post calls authentication function
* @param None
* @return None
*/
"""
func request_authentication() -> int:
	var user: String = Save.game_data.username
	
	var result: int = yield(server_connection.authenticate_async(), "completed")
	if result == OK:
		print("Authenticated user %s successfully" % user)
	else:
		print("Could not authenticate user %s" % user)
	return result

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
func _on_ServerConnection_chat_message_received(text,type,user_sent_to,user_received_from):
	print("message received from %s" % user_received_from)
	chat_box.add_message(text,type,user_sent_to,user_received_from)

"""
/*
* @pre called when user submits message to chatbox
* @post sends message to send_text_async function
* @param msg -> String
* @return None
*/
"""
func _on_chatbox_message_sent(msg,is_whisper,username_to_send_to):
	if is_whisper:
		yield(server_connection.join_chat_async_whisper(username_to_send_to,false), "completed")
		var t = Timer.new()
		t.set_wait_time(0.1)
		t.set_one_shot(true)
		self.add_child(t)
		t.start()
		yield(t, "timeout")
		t.queue_free()
		yield(server_connection.send_text_async_whisper(msg,username_to_send_to), "completed")
	else:
		yield(server_connection.send_text_async_general(msg), "completed")
	print("sent message to server")
