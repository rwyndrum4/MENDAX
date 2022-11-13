"""
* Programmer Name - Freeman Spray, Ben Moeller
* Description - Code for controlling what happens in the entry space scene
* Date Created - 10/3/2022
* Date Revisions:
	10/8/2022 - Added the ability to go into settings from scene with enter key
	11/5/2022 - Added ability to transition to further minigames after the first
"""
extends Control

# Member Variables
var in_exit = false
var in_menu = false
onready var instructions: Label = $exitCaveArea/exitDirections
onready var settingsMenu = $GUI/SettingsMenu
onready var myTimer: Timer = $GUI/Timer
onready var timerText: Label = $GUI/Timer/timerText
onready var textBox = $GUI/textBox
onready var player_one = $Player

var other_player = "res://Scenes/player/other_players/other_players.tscn"

"""
/*
* @pre Called when the node enters the scene tree for the first time.
* @post updates starts the timer
* @param None
* @return None
*/
"""
func _ready():
	#Spawn the players if a match is ongoing
	if ServerConnection.match_exists():
		spawn_players()
	#hide cave instructions at start
	instructions.hide()
	myTimer.start(90)
	# warning-ignore:return_value_discarded
	GlobalSignals.connect("openChatbox", self, "chatbox_use")


"""
/*
* @pre Called for every frame
* @post updates timer and changes scenes if player presses enter and is in the zone
* @param _delta -> time variable that can be optionally used
* @return None
*/
"""
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta): #change to delta if used
	check_settings()
	timerText.text = convert_time(myTimer.time_left)

"""
/*
* @pre An input of any sort
* @post None
* @param Takes in an event
* @return None
*/
"""
func _input(ev):
	if in_exit:
		if Input.is_action_just_pressed("ui_accept",false) and not Input.is_action_just_pressed("ui_enter_chat"):
			# warning-ignore:return_value_discarded
			Global.state = Global.scenes.MAIN_MENU #change scene to main menu
	#DEBUG PURPOSES - REMOVE FOR FINAL GAME!!!
	#IF YOU PRESS P -> TIMER WILL REDUCE TO 3 SECONDS
	if Input.is_action_just_pressed("debug_key",false):
		myTimer.start(3)
"""
/*
* @pre Ca	velocity = move_and_slide(velocity)lled when player enters the Area2D zone
* @post shows instructions on screen and sets in_cave to true
* @param _body -> body of the player
* @return None
*/
"""
func _on_exitCaveArea_body_entered(_body: PhysicsBody2D): #change to body if want to use
	instructions.show()
	in_exit = true
	
"""
/*
* @pre Called when player exits the Area2D zone
* @post hides instructions on screen and sets in_cave to false
* @param _body -> body of the player
* @return None
*/
"""
func _on_exitCaveArea_body_exited(_body: PhysicsBody2D): #change to body if want to use
	in_exit = false
	instructions.hide()

"""
/*
* @pre Called for every frame inside process function
* @post Opens and closes settings when escape is pressed
* @param None
* @return None
*/
"""
func check_settings():
	if Input.is_action_just_pressed("ui_cancel",false) and not in_menu:
		settingsMenu.popup_centered_ratio()
		in_menu = true
	elif Input.is_action_just_pressed("ui_cancel",false) and in_menu:
		settingsMenu.hide()
		in_menu = false

"""
/*
* @pre Called when need to convert seconds to MIN:SEC format
* @post Returns string of current time
* @param time_in -> float 
* @return String (text of current time left)
*/
"""
func convert_time(time_in:float) -> String:
	var rounded_time = int(time_in)
	var minutes: int = rounded_time/60
	var seconds: int = rounded_time - (minutes*60)
	return str(minutes,":",seconds)

"""
/*
* @pre Called when the timer hits 0
* @post Changes scene to minigame
* @param None
* @return String (text of current time left)
*/
"""
func _on_Timer_timeout():
	#change scene to riddler minigame
	if Global.minigame == 0:
		Global.minigame = 1
		Global.state = Global.scenes.RIDDLER_MINIGAME
	#change scene to arena minigame
	elif Global.minigame == 1:
		Global.minigame = 2
		Global.state = Global.scenes.ARENA_MINIGAME

"""
/*
* @pre None
* @post Sets in_menu to true
* @param value
* @return None
*/
"""
func chatbox_use(value):
	if value:
		in_menu = true

"""
/*
* @pre called when players need to be spawned in (assuming server is online)
* @post Spawns players that move with server input and sets position regular player
* @param None
* @return None
*/
"""
func spawn_players():
	#set initial position the players should be on spawn
	set_init_player_pos()
	#num_str is the player number (1,2,3,4)
	for num_str in Global.player_positions:
		#Add animated player to scene
		var num = int(num_str)
		#if player is YOUR player (aka player you control)
		if num == ServerConnection._player_num:
			player_one.position = Global.player_positions[str(num)]
			player_one.set_color(num)
		#if the player is another online player
		else:
			var new_player:KinematicBody2D = load(other_player).instance()
			new_player.set_player_id(num)
			new_player.set_color(num)
			#Change size and pos of sprite
			new_player.position = Global.player_positions[str(num)]
			#Add child to the scene
			add_child(new_player)
		#Set initial input vectors to zero
		Global.player_input_vectors[str(num)] = Vector2.ZERO

"""
/*
* @pre None
* @post Sets players to intial positions by cave entrance
* @param None
* @return None
*/
"""
func set_init_player_pos():
	#num_str is the player number (1,2,3,4)
	for num_str in Global.player_positions:
		var num = int(num_str)
		match num:
			1: Global._player_positions_updated(num,Vector2(800,1550))
			2: Global._player_positions_updated(num,Vector2(880,1550))
			3: Global._player_positions_updated(num,Vector2(800,1450))
			4: Global._player_positions_updated(num,Vector2(880,1450))
			_: printerr("THERE ARE MORE THAN 4 PLAYERS TRYING TO BE SPAWNED IN EntrySpace.gd")
