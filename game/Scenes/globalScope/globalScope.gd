"""
* Programmer Name - Ben Moeller, Jason Truong
* Description - File for controlling swapping out scenes and controlling network and chatbox
* 	This is the scnene that will ALWAYS be a part of the game
*	If you want to know how to load a scene, checkout instructions in Loader/Global.gd
* Date Created - 10/9/2022
* Date Revisions:
	10/12/2022 - Start of adding network functionality
	10/14/2022 - Got general chat working for player
	10/22/2022 - Adding scene changer functionality
"""
extends Node

#Member Variables
onready var chat_box = $GUI/chatbox
onready var settings_menu = $GUI/SettingsMenu
onready var world_env = $WorldEnvironment
onready var fps_label = $GUI/fpsLabel

#Scene Paths
var main_menu = "res://Scenes/mainMenu/mainMenu.tscn"
var market = "res://Scenes/StoreElements/StoreVars.tscn"
var start_area = "res://Scenes/startArea/startArea.tscn"
var cave = "res://Scenes/startArea/EntrySpace.tscn"
var riddler_minigame = "res://Scenes/minigames/riddler/riddleGame.tscn"
var arena_minigame = "res://Scenes/minigames/arena/arenaGame.tscn"
var gameover = "res://Scenes/mainMenu/gameOver.tscn"

#Current scene running
var current_scene = null
#State to compare to the global state to see if anything changes
var local_state = null
#Bool to tell if in a popup or not
var in_popup: bool = false
#Bools to tell if in chatbox or not, work like a locking mechanism
var in_chatbox: bool = false
#Bools to tell if you can open the settings or not
var can_open_settings: bool = false

"""
/*
* @pre called once when scene is called
* @post authenticates, connects to server, and joins general chat
* @param None
* @return None
*/
"""
func _ready():
	# warning-ignore:return_value_discarded
	ServerConnection.connect("chat_message_received",self,"_on_ServerConnection_chat_message_received")
	# warning-ignore:return_value_discarded
	GlobalSignals.connect("openChatbox",self,"_chatbox_use")
	#Initialize the options menu and world environment
	initialize_settings()
	initialize_world_env()
	initialize_fps_label()
	#Load initial scene (main menu)
	current_scene = load(main_menu).instance()
	add_child(current_scene)
	Global.state = Global.scenes.MAIN_MENU
	local_state = Global.scenes.MAIN_MENU
	#Connect to Server and join world
	yield(server_checks(), "completed")

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
	#Change scene
	if local_state != Global.state:
		#free up memory from the current scene if not a popup scene (example: settings menu)
		if not_popup(Global.state):
			current_scene.queue_free()
		#change the scene
		_change_scene_to(Global.state)
	if Input.is_action_just_pressed("ui_cancel",false) and local_state != Global.scenes.MAIN_MENU:
		if in_popup:
			settings_menu.hide()
			in_popup = false
		elif can_open_settings:
			settings_menu.popup_centered_ratio()
			in_popup = true
	set_popup_locks()
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
	elif state == Global.scenes.OPTIONS_FROM_MAIN:
		settings_menu.popup_centered_ratio()
		Global.state = Global.scenes.MAIN_MENU
		return
	elif state == Global.scenes.MARKET:
		current_scene = load(market).instance()
	elif state == Global.scenes.START_AREA:
		current_scene = load(start_area).instance()
	elif state == Global.scenes.CAVE:
		current_scene = load(cave).instance()
	elif state == Global.scenes.RIDDLER_MINIGAME:
		current_scene = load(riddler_minigame).instance()
	elif state == Global.scenes.ARENA_MINIGAME:
		current_scene = load(arena_minigame).instance()
	elif state == Global.scenes.GAMEOVER:
		current_scene = load(gameover).instance()
	#add scene to tree and revise local state
	add_child(current_scene)
	local_state = Global.state

"""
/*
* @pre called once in _ready function
* @post authenticates, connects to server, and joins general chat
* 	if there were no errors along the way
* @param None
* @return bool
*/
"""
func server_checks():
	ServerConnection.set_server_status(false)
	var result = yield(request_authentication(), "completed")
	if result == OK:
		result = yield(connect_to_server(), "completed")
		if result == OK:
			result = yield(ServerConnection.join_chat_async_general(), "completed")
			if result == OK:
				ServerConnection.set_server_status(true)

"""
/*
* @pre called in _ready
* @post calls authentication function
* @param None
* @return int
*/
"""
func request_authentication() -> int:
	var user: String = Save.game_data.username
	
	var result: int = yield(ServerConnection.authenticate_async(), "completed")
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
* @return int
*/
"""
func connect_to_server() -> int:
	var result: int = yield(ServerConnection.connect_to_server_async(), "completed")
	if result == OK:
		print("Connected to the server")
	elif ERR_CANT_CONNECT:
		print("Could not connect to server")
	else:
		print("Unexpected error received")
	return result

"""
/*
* @pre called once to authenticate user
* @post connects to the server
* @param username -> String, text -> String
* @return None
*/
"""
func _on_ServerConnection_chat_message_received(msg,type,user_sent,from_user):
	#add message from server to chatbox
	chat_box.add_message(msg,type,user_sent,from_user)
	GlobalSignals.emit_signal("answer_received",msg)

"""
/*
* @pre called when user submits message to chatbox
* @post sends message to send_text_async function
* @param msg -> String
* @return None
*/
"""
func _on_chatbox_message_sent(msg,is_whisper,username_to_send_to):
	#If not connected to server, don't send message
	if not ServerConnection.get_server_status():
		chat_box.add_err_message()
		return
	#Else send message corresponding to whisper or general
	if is_whisper:
		yield(ServerConnection.join_chat_async_whisper(username_to_send_to,false), "completed")
		#Set a timer to give time for connection to form between players
		var t = Timer.new()
		t.set_wait_time(0.5)
		t.set_one_shot(true)
		self.add_child(t)
		t.start()
		yield(t, "timeout")
		t.queue_free()
		#end of timer, send whisper
		yield(ServerConnection.send_text_async_whisper(msg,username_to_send_to), "completed")
	else:
		#send message to general
		ServerConnection.send_chat_message(msg)

"""
/*
* @pre called in the _ready func
* @post initializes the settings menu for values look same
* @param None
* @return None
*/
"""
func initialize_settings():
	#Call functions to sync audio settings with user save
	settings_menu._on_MasterVolSlider_value_changed(Save.game_data.master_vol)
	settings_menu._on_MusicVolSlider_value_changed(Save.game_data.music_vol)
	settings_menu._on_SfxVolSlider_value_changed(Save.game_data.sfx_vol)

func initialize_world_env():
	#Call functions to use user saved brightness and bloom values
	world_env._on_brightness_toggled(Save.game_data.brightness)
	world_env._on_bloom_toggled(Save.game_data.bloom_on)


func initialize_fps_label():
	#Call function to use user saved fps
	fps_label._on_fps_displayed(Save.game_data.display_fps)

"""
/*
* @pre None
* @post tells if the scene is a popup scene or not
* @param state -> Global.scenes
* @return bool
*/
"""
func not_popup(state) -> bool:
	match state:
		Global.scenes.OPTIONS_FROM_MAIN:
			return false
		_:
			return true

"""
/*
* @pre called when chatbox is opened
* @post sets in_chatbox to true so game knows chat is being used
* @param value -> bool 
* @return None
*/
"""
func _chatbox_use(value):
	in_chatbox = value

"""
/*
* @pre None
* @post sets locks for if settings menu can be opened or not
* @param None
* @return None
*/
"""
func set_popup_locks():
	if not in_chatbox and not can_open_settings:
		can_open_settings = true
	elif in_chatbox and can_open_settings:
		can_open_settings = false
