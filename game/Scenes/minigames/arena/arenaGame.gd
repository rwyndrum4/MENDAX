"""
* Programmer Name - Freeman Spray
* Description - Code for controlling the Arena minigame
* Date Created - 11/5/2022
* Date Revisions: 11/12/2022 - added physics process to manage Skeleton positioning
*				  11/13/2022 - got Skeleton to track a player
* 				  11/15/2022 - move physics process to Skeleton.gd
				  11/28/2022 - add win condition in form of transition back to cave
"""
extends Control

# Member Variables
var in_menu = false
var enemies_remaining = 2
onready var myTimer: Timer = $GUI/Timer
onready var timerText: Label = $GUI/Timer/timerText
onready var player = $Player
onready var swordPivot = $Player/Sword/pivot
onready var sword = $Player/Sword
onready var playerHealth = $Player/ProgressBar
#Scene for players that online oppenents use
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
	myTimer.start(90)
	# warning-ignore:return_value_discarded
	GlobalSignals.connect("openChatbox", self, "chatbox_use")
	playerHealth.visible = true
	playerHealth.value = 100
	sword.direction = "right"
	swordPivot.position = player.position + Vector2(60,20)
	#If there is a server connection, spawn all players
	if ServerConnection.match_exists():
		spawn_players()
	# Add signal-catching function to check for win condition after each enemy is defetaed
	GlobalSignals.connect("enemyDefeated",self,"_enemy_defeated")

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
	timerText.text = convert_time(myTimer.time_left)
	if sword.direction == "right":
		swordPivot.position = player.position + Vector2(60,0)
	if sword.direction == "left":
		swordPivot.position = player.position + Vector2(-60,0)
		
"""
/*
* @pre An input of any sort
* @post None
* @param Takes in an event
* @return None
*/
"""
func _input(_ev):
	#DEBUG PURPOSES - REMOVE FOR FINAL GAME!!!
	#IF YOU PRESS P -> TIMER WILL REDUCE TO 3 SECONDS
	if Input.is_action_just_pressed("timer_debug_key",false):
		myTimer.start(3)
	#IF YOU PRESS O (capital 'o') -> TIMER WILL INCREASE TO ARBITRARILY MANY SECONDS
	if Input.is_action_just_pressed("extend_timer_debug_key",false):
		myTimer.start(30000)

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
	playerHealth.visible = false
	Global.state = Global.scenes.CAVE

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
	set_init_player_pos()
	#num_str = player number (1,2,3,4)
	for num_str in Global.player_positions:
		#Add animated player to scene
		var num = int(num_str)
		#if player is YOUR player (aka player you control)
		if num == ServerConnection._player_num:
			player.position = Global.player_positions[str(num)]
			player.set_color(num)
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
			1: Global._player_positions_updated(num,Vector2(800,1350))
			2: Global._player_positions_updated(num,Vector2(880,1350))
			3: Global._player_positions_updated(num,Vector2(800,1250))
			4: Global._player_positions_updated(num,Vector2(880,1250))
			_: printerr("THERE ARE MORE THAN 4 PLAYERS TRYING TO BE SPAWNED IN arenaGame.gd")
			
"""
/*
* @pre Called when an enemy signals that it has been killed
* @post scene transitions back to cave
* @param Takes an enemyID value (not used)
* @return None
*/
"""	
func _enemy_defeated(_enemyID:int):
	enemies_remaining = enemies_remaining - 1
	if enemies_remaining == 0:
		Global.state = Global.scenes.CAVE
