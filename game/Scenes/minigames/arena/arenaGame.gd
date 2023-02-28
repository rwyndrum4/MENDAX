"""
* Programmer Name - Freeman Spray, Ben Moeller
* Description - Code for controlling the Arena minigame
* Date Created - 11/5/2022
* Date Revisions: 11/12/2022 - added physics process to manage Skeleton positioning
*				  11/13/2022 - got Skeleton to track a player
* 				  11/15/2022 - move physics process to Skeleton.gd
				  11/28/2022 - add win condition in form of transition back to cave
"""
extends Control

# Member Variables
const TOTAL_TIME = 180
var _enemies: Array = []
var game_started = false
var enemies_remaining = 9
onready var myGUI = $GUI
onready var myTimer: Timer = $GUI/Timer
onready var timerText: Label = $GUI/Timer/timerText
onready var textBox = $textBox
onready var main_player = $Player
onready var swordPivot = $Player/Sword/pivot
onready var sword = $Player/Sword
onready var playerHealth = $Player/ProgressBar
onready var SkeletonEnemy = preload("res://Scenes/Mobs/skeleton.tscn")
onready var BodEnemy = preload("res://Scenes/Mobs/BoD.tscn")
onready var ChandelierEnemy = preload("res://Scenes/Mobs/chandelier.tscn")
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
var alive_players: Dictionary = {}
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
	randomize()
	# warning-ignore:return_value_discarded
	GlobalSignals.connect("openChatbox", self, "chatbox_use")
	# warning-ignore:return_value_discarded
	GlobalSignals.connect("enemyDefeated",self,"_enemy_defeated")
	# warning-ignore:return_value_discarded
	Global.connect("all_players_arrived", self, "_can_start_game")
	# warning-ignore:return_value_discarded
	ServerConnection.connect("minigame_can_start", self, "_can_start_game_other")
	playerHealth.visible = true
	playerHealth.value = 100
	sword.direction = "right"
	swordPivot.position = main_player.position + Vector2(60,20)
	#If there is a server connection, spawn all players
	if ServerConnection.match_exists() and ServerConnection.get_server_status():
		ServerConnection.send_spawn_notif()
		spawn_players()
		# warning-ignore:return_value_discarded
		ServerConnection.connect("arena_enemy_hit",self,"someone_hit_enemy")
		# warning-ignore:return_value_discarded
		ServerConnection.connect("arena_player_lost_health",self,"other_player_hit")
		# warning-ignore:return_value_discarded
		ServerConnection.connect("arena_player_swung_sword",self,"other_player_swung_sword")
		if ServerConnection._player_num == 1:
			#in case p1 is last player to get to minigame
			if Global.get_minigame_players() == Global.get_num_players() - 1:
				ServerConnection.send_minigame_can_start()
				game_started = true
				start_arena_game()
			#Sends the riddle to other players once all are present
		else:
			#If player doesn't receive riddle from server in 5 seconds, they get their own riddle
			#If they got the riddle successfully nothing else will happen
			var wait_for_start: Timer = Timer.new()
			add_child(wait_for_start)
			wait_for_start.wait_time = 5
			wait_for_start.one_shot = true
			wait_for_start.start()
			# warning-ignore:return_value_discarded
			wait_for_start.connect("timeout",self, "_start_timer_expired", [wait_for_start])
		var change_target_timer: Timer = Timer.new()
		add_child(change_target_timer)
		change_target_timer.wait_time = 8
		change_target_timer.one_shot = false
		change_target_timer.start()
		# warning-ignore:return_value_discarded
		change_target_timer.connect("timeout",self, "_target_timer_expired")
	#else if single player game
	else:
		myTimer.start(TOTAL_TIME)
		start_arena_game()

"""
/*
* @pre Called in ready function
* @post spawns all enemies in
* @param None
* @return None
*/
"""
func spawn_enemies() -> void:
	var enemy_id = 0
	#Spawn 3 Skeletons
	var Skel_positions = [Vector2(1750,700),Vector2(2400,700),Vector2(2900,3000)]
	for i in range(3):
		var s = SkeletonEnemy.instance()
		s.position = Skel_positions[i]
		s.scale = Vector2(3,3)
		if i == 0:
			add_child(s)
		s.set_physics_process(false)
		s.set_id(enemy_id)
		_enemies.append(s)
		enemy_id += 1
	#Spawn 2 BoDs
	var BoD_positions = [Vector2(2750,750), Vector2(1000,3000)]
	for i in range(2):
		var b = BodEnemy.instance()
		b.position = BoD_positions[i]
		b.scale = Vector2(3,3)
		add_child(b)
		b.set_physics_process(false)
		b.set_id(enemy_id)
		_enemies.append(b)
		enemy_id += 1
	#Spawn 4 Chandeliers
	var Cha_positions = [Vector2(500,500),Vector2(3300,500),Vector2(500,3250), Vector2(3300,3250)]
	for i in range(4):
		var c = ChandelierEnemy.instance()
		c.position = Cha_positions[i]
		c.scale = Vector2(3,3)
		add_child(c)
		c.set_physics_process(false)
		c.set_id(enemy_id)
		_enemies.append(c)
		enemy_id += 1

"""
/*
* @pre Called once start time expires (happens once)
* @post deletes timer and starts game if necessary
* @param timer -> Timer
* @return None
*/
"""
func _start_timer_expired(timer):
	timer.queue_free()
	if not game_started:
		game_started = true
		start_arena_game()

"""
/*
* @pre Called once all players have spawned into the minigame
* 	only run by PLAYER 1
* @post sends signal to other players to start, and start game
* @param None
* @return None
*/
"""
func _can_start_game():
	game_started = true
	ServerConnection.send_minigame_can_start()
	myTimer.start(TOTAL_TIME)
	start_arena_game()

"""
/*
* @pre Called when non-player 1 player receives signal to start game
* @post starts the game if timer hasn't already done it for it
* @param None
* @return None
*/
"""
func _can_start_game_other():
	if not game_started:
		game_started = true
		myTimer.start(TOTAL_TIME)
		start_arena_game()

"""
/*
* @pre Signal to start has been received
* @post starts the game, queues instruction text
* @param None
* @return None
*/
"""
func start_arena_game():
	$GUI/wait_on_players.queue_free()
	textBox.queue_text("You have a minute to defeat all enemies.")
	textBox.queue_text("Each enemy will become stronger once this time has passed.")
	textBox.queue_text("If any one of you dies, I will reset the timer.")
	textBox.queue_text("Let the strongest among you prevail.")
	spawn_enemies()
	#game will start once all text in textBox is out of the queue

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
	if is_instance_valid(myTimer):
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
* @return None
*/
"""
func _on_Timer_timeout():
	#Make enemies harder ( ´ ｰ `)
	for en in _enemies:
		if is_instance_valid(en):
			en.level_up()
			en.set_physics_process(false)
	textBox.queue_text("OUT OF TIME. NOW PERISH.")
	myTimer.queue_free()

"""
/*
* @pre Called when the target timer hits 0
* @post changes which target skeleton targets
* @param None
* @return None
*/
"""
func _target_timer_expired():
	var p_tgt = 0
	var found = false
	for p in alive_players.keys():
		if found:
			alive_players[p] = true
			p_tgt = p
			break
		if alive_players[p]:
			found = true
			alive_players[p] = false
	if p_tgt == 0:
		p_tgt = alive_players.keys()[0]
		alive_players[p_tgt] = true
	for en in _enemies:
		if is_instance_valid(en):
			if en._name == "s":
				en.slow_speed()
				en.update_target(p_tgt)

"""
/*
* @pre all enemies have died
* @post sends players back to the cave
* @param None
* @return String (text of current time left)
*/
"""
func _end_game():
	#Turn off player healthbar
	playerHealth.visible = false
	#Delete online player objects if they have not already died
	for o_player in server_players:
		var obj = o_player.get('player_obj') 
		if obj != null:
			obj.queue_free()
	Global.reset_minigame_players()
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
		if num == 1:
			alive_players[num] = true
		else:
			alive_players[num] = false
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
			var p_obj = o_player.get('player_obj')
			p_obj.take_damage(player_health)
			Global.player_health[str(player_id)]=player_health
			#print(Global.player_health[str(player_id)])
			break

"""
/*
* @pre received update from server
* @post updates the health of enemy hit
* @param enemy_id -> int (enum value of enemy to edit), dmg_taken
* @return None
*/
"""
func someone_hit_enemy(enemy_id: int, dmg_taken: int, player_id: int,enemy_type:String):
	if is_instance_valid(_enemies[enemy_id]):
		var e = _enemies[enemy_id]
		e.take_damage_server(dmg_taken)
		if enemy_type == "c":
			Global.chandelier_damage[str(player_id)]+=dmg_taken
		elif enemy_type == "s":
			Global.skeleton_damage[str(player_id)]+=dmg_taken
		elif enemy_type == "d":
			Global.bod_damage[str(player_id)]+=dmg_taken

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
func _extend_timer(p_id: int):
	# warning-ignore:return_value_discarded
	alive_players.erase(p_id)
	var new_time: float = myTimer.time_left + EXTRA_TIME
	myTimer.start(new_time)
			
"""
/*
* @pre Called when an enemy signals that it has been killed
* @post makes announcement, hides player health, and transitions scene back to cave
* @param Takes an enemyID value (not used)
* @return None
*/
"""	
func _enemy_defeated(enemyID:int):
	enemies_remaining = enemies_remaining - 1
	#Spawn another skeleton after one before it dies
	#enemyID 0 and 1 were skeletons, and 2 will be the last that spawns
	#there will be 3 in total
	if enemyID == 0:
		add_child(_enemies[1])
	if enemyID == 1:
		add_child(_enemies[2])
	#If no more enemies remaining
	if enemies_remaining == 0:
		textBox.queue_text("Those strongest among you who remain have leave to prepare for the next trial.")
		# Wait 5 seconds
		var t = Timer.new()
		t.set_wait_time(3)
		t.set_one_shot(false)
		self.add_child(t)
		t.start()
		yield(t, "timeout")
		t.queue_free()
		#Go back to cave
		_end_game()
