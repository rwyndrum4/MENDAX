"""
* Programmer Name - Freeman Spray
* Description - Code for controlling the Arena minigame
* Date Created - 11/5/2022
* Date Revisions: 11/12/2022 - added physics process to manage Skeleton positioning
*				  11/13/2022 - got Skeleton to track a player
* 				  11/15/2022 - move physics process to Skeleton.gd
"""
extends Control

# Member Variables
onready var myTimer: Timer = $GUI/Timer
onready var timerText: Label = $GUI/Timer/timerText
onready var main_player = $Player
onready var swordPivot = $Player/Sword/pivot
onready var sword = $Player/Sword
onready var playerHealth = $Player/ProgressBar
onready var SkeletonEnemy = $Skeleton
onready var BodEnemy = $BoD
#Scene for players that online oppenents use
var online_players = "res://Scenes/player/arena_player/arena_player.tscn"

#Enemy Types in terms of numbers, used with server code
enum EnemyTypes {
	SKELETON = 1,
	CHANDELIER,
	BOD
}
#Array to hold objects of other players (not your own player)
var server_players: Array = []
var in_menu = false
var EXTRA_TIME: float = 20.0
var _player_dead = false #variable to track if player 1 has died

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
	swordPivot.position = main_player.position + Vector2(60,20)
	#If there is a server connection, spawn all players
	if ServerConnection.match_exists() and ServerConnection.get_server_status():
		spawn_players()
		# warning-ignore:return_value_discarded
		ServerConnection.connect("arena_enemy_hit",self,"someone_hit_enemy")
		# warning-ignore:return_value_discarded
		ServerConnection.connect("arena_player_lost_health",self,"other_player_hit")
		# warning-ignore:return_value_discarded
		ServerConnection.connect("arena_player_swung_sword",self,"other_player_swung_sword")

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
	if not is_instance_valid(main_player):
		return
	if sword.direction == "right":
		swordPivot.position = main_player.position + Vector2(60,0)
	elif sword.direction == "left":
		swordPivot.position = main_player.position + Vector2(-60,0)

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
	var seconds = rounded_time - (minutes*60)
	if seconds < 10:
		seconds = str(0) + str(seconds)
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
	#Turn off player healthbar
	playerHealth.visible = false
	#Delete online player objects if they have not already died
	for o_player in online_players:
		var obj = o_player.get('player_obj')
		if obj != null:
			obj.queue_free()
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
	#num_str -> player number (1,2,3,4)
	for num_str in Global.player_positions:
		#Add animated player to scene
		var num = int(num_str)
		#if player is YOUR player (aka player you control)
		if num == ServerConnection._player_num:
			main_player.position = Global.player_positions[str(num)]
			main_player.set_color(num)
		#if the player is another online player
		else:
			var new_player:KinematicBody2D = load(online_players).instance()
			new_player.set_player_id(num)
			new_player.set_color(num)
			#Change size and pos of sprite
			new_player.position = Global.player_positions[str(num)]
			#Add child to the scene
			add_child(new_player)
			# warning-ignore:return_value_discarded
			new_player.connect("player_died", self, "_extend_timer")
			server_players.append({
				'num': num,
				'player_obj': new_player,
				'sword_dir': "right"
			})
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

"""
/*
* @pre received update from server
* @post updates the health of player that was hit
* @param player_id -> int (id of player hit), player_health -> int (new health value)
* @return None
*/
"""
func other_player_hit(player_id: int, player_health: int):
	for o_player in server_players:
		if player_id == o_player.get('num'):
			o_player.get('player_obj').healthbar.value = player_health
			break

"""
/*
* @pre received update from server
* @post updates the health of enemy hit
* @param enemy_id -> int (enum value of enemy to edit), dmg_taken
* @return None
*/
"""
func someone_hit_enemy(enemy_id: int, dmg_taken: int):
	if enemy_id == EnemyTypes.SKELETON:
		SkeletonEnemy.take_damage_server(dmg_taken)
	elif enemy_id == EnemyTypes.BOD:
		BodEnemy.take_damage_server(dmg_taken)
	elif enemy_id == EnemyTypes.CHANDELIER:
		pass #implement when chandelier is ready

"""
/*
* @pre received update from server
* @post game sets player who swung to swing their sword
* @param player_id -> int (number of player to be updated)
* @return None
*/
"""
func other_player_swung_sword(player_id: int, direction: String):
	for o_player in server_players:
		if player_id == o_player.get('num'):
			o_player['sword_dir'] = direction
			o_player.get('player_obj').swing_sword(direction)
			break

"""
/*
* @pre a player (who is not the player playing) has died
* @post timer gains more time
* @param None
* @return None
*/
"""
func _extend_timer():
	var new_time: float = myTimer.time_left + EXTRA_TIME
	myTimer.start(new_time)
