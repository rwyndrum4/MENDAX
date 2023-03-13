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
var TOTAL_TIME = 180 #Total time for game until hard mode starts
const EXTRA_TIME: float = 20.0 #Extra time that is added when someone dies
var enemies_remaining = 9 #How many enemies are left, if 0 you win
var _enemies: Array = [] #Array that holds enemy objects, enemy_id == index
var server_players: Array = [] #Array to hold objects of other players (not your own)
var alive_players: Dictionary = {} #Dictionary that holds who is alive (4 online play)
var game_started = false #track if game has started or not
var _player_dead = false #variable to track if player 1 has died
var _shield_spawn = null #track where shield is
var _shield_available:bool = true #track if shield can be taken

# Game objects
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
onready var littleGuyEnemy = preload("res://Scenes/minigames/arena/littleGuy.tscn")
onready var onlinePlayer = preload("res://Scenes/player/arena_player/arena_player.tscn")

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
	GlobalSignals.connect("enemyDefeated",self,"_enemy_defeated")
	# warning-ignore:return_value_discarded
	Global.connect("all_players_arrived", self, "_can_start_game")
	# warning-ignore:return_value_discarded
	ServerConnection.connect("minigame_can_start", self, "_can_start_game_other")
	playerHealth.visible = true
	playerHealth.value = 150
	sword.direction = "right"
	swordPivot.position = main_player.position + Vector2(60,20)
	#If there is a server connection, spawn all players
	if ServerConnection.match_exists() and ServerConnection.get_server_status():
		TOTAL_TIME = 60
		ServerConnection.send_spawn_notif()
		spawn_players()
		# warning-ignore:return_value_discarded
		ServerConnection.connect("arena_enemy_hit",self,"someone_hit_enemy")
		# warning-ignore:return_value_discarded
		ServerConnection.connect("arena_player_lost_health",self,"other_player_hit")
		# warning-ignore:return_value_discarded
		ServerConnection.connect("arena_player_swung_sword",self,"other_player_swung_sword")
		# warning-ignore:return_value_discarded
		ServerConnection.connect("character_took_shield",self,"someone_took_shild")
		# warning-ignore:return_value_discarded
		ServerConnection.connect("player_booped",self,"someone_got_booped")
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
		TOTAL_TIME = 180
		myTimer.start(TOTAL_TIME)
		start_arena_game()

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
	#Game is over if all players dead
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
	var var_time: String = "a minute" if TOTAL_TIME == 120 else "two minutes"
	textBox.queue_text("You have " + var_time + " to defeat all enemies.")
	textBox.queue_text("Each enemy will become stronger once this time has passed.")
	textBox.queue_text("If any one of you dies, I will add more time.")
	textBox.queue_text("Let the strongest among you prevail.")
	spawn_enemies()
	spawn_shield()
	#game will start once all text in textBox is out of the queue

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
		#If enemy has died do skip it
		if not is_instance_valid(en):
			continue
		#If enemy has not died and was spawned in
		elif en._has_spawned:
			en.level_up()
			en.set_physics_process(false)
		#If enemy has not had the chance to spawn in
		elif not en._has_spawned:
			en._leveled_up = true
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
func _end_game(won_game:bool):
	$GUI/YouDied.hide()
	#Display text letting them know how the game went
	var text = "Those strongest among you who remain have leave to prepare for the next trial."
	if not won_game:
		text = "You lot have failed, I expect better next time"
	textBox.queue_text(text)
	#Spawn and show end screen with results
	var end_screen:Popup = load("res://Scenes/minigames/arena/arenaResults.tscn").instance()
	$GUI.add_child(end_screen)
	var server_status = ServerConnection.match_exists() and ServerConnection.get_server_status()
	end_screen.add_results(gen_results(server_status))
	end_screen.popup_centered()
	#Give players 5 seconds to read everything
	var t = Timer.new()
	t.set_wait_time(5)
	t.set_one_shot(false)
	self.add_child(t)
	t.start()
	yield(t, "timeout")
	t.queue_free()
	#Cleanup objects and leave minigame
	#Delete online player objects if they have not already died
	for o_player in server_players:
		var obj = o_player.get('player_obj') 
		if obj != null:
			obj.queue_free()
	Global.reset_minigame_players()
	Global.state = Global.scenes.CAVE


"""
/*
* @pre game has ended
* @post generates results based on if server is being used or not
* @param server_status -> bool (if server is on or not)
* @return Dictionary
*/
"""
func gen_results(server_on:bool) -> Dictionary:
	if server_on:
		var res: Dictionary = {}
		#Adding money for all players in server
		for p in server_players:
			var p_num = p.get('num')
			var p_name = Global.get_player_name(p_num)
			if p.get('player_obj') == null:
				res[p_name] = "Died"
			else:
				GameLoot.add_to_coin(p_num,20)
				if Save.game_data.username == p_name:
					PlayerInventory.add_item("Coin", 20)
				res[p_name] = "Lived"
		#Adding money for you 
		res[Save.game_data.username] = "Died" if _player_dead else "Lived"
		var your_num = ServerConnection._player_num
		if not _player_dead:
			GameLoot.add_to_coin(your_num,20)
		get_parent().change_money(GameLoot.get_coin_val(your_num))
		return res
	else:
		if not _player_dead:
			GameLoot.add_to_coin(1,20)
			PlayerInventory.add_item("Coin", 20)
		get_parent().change_money(GameLoot.get_coin_val(1))
		return {Save.game_data.username: "Died" if _player_dead else "Lived"}

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
		s.set_name("skeleton" + str(enemy_id))
		_enemies.append(s)
		enemy_id += 1
	#Spawn 2 BoDs
	var BoD_positions = [Vector2(2750,750), Vector2(1000,3000)]
	for i in range(2):
		var b = BodEnemy.instance()
		b.position = BoD_positions[i]
		b.scale = Vector2(3,3)
		if i == 0:
			add_child(b)
		b.set_physics_process(false)
		b.set_id(enemy_id)
		b.set_name("BoD" + str(enemy_id))
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
		c.set_name("chandelier" + str(enemy_id))
		_enemies.append(c)
		enemy_id += 1
	#Spawn 4 littleGuys
	var Guy_positions = [Vector2(1000,750),Vector2(1000,1500),Vector2(1000,2100),Vector2(1000,3000)]
	for i in range(4):
		var l = littleGuyEnemy.instance()
		l.position = Guy_positions[i]
		add_child(l)

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
			var new_player:KinematicBody2D = onlinePlayer.instance()
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
	if len(alive_players) == 0:
		_end_game(true)
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
	#Same logic as above, but spawn extra BoD
	if enemyID == 3:
		add_child(_enemies[4])
		_enemies[4].turn_on_physics()
	#If no more enemies remaining you win!!!
	if enemies_remaining == 0:
		_end_game(true)

"""
/*
* @pre Called when a player dies in the arena
* @post zoom out to watch other players
* @param None
* @return None
*/
"""
func spectate_mode():
	var spec_cam = Camera2D.new()
	add_child(spec_cam)
	spec_cam.clear_current()
	spec_cam.make_current()
	spec_cam.zoom = Vector2(5,5)
	spec_cam.position = Vector2(1900,1920)
	$GUI/YouDied.show()
	if len(alive_players) == 0:
		_end_game(false)
		return

"""
/*
* @pre None
* @post Shield is spawned inside of game
* @param None
* @return None
*/
"""
func spawn_shield():
	# Generate shild spawn
	_shield_spawn = Area2D.new()
	var col_2d = CollisionShape2D.new()
	var shape = CircleShape2D.new()
	shape.set_radius(80)
	col_2d.set_shape(shape)
	_shield_spawn.position = Vector2(1882,1900)
	var shield_sprite = Sprite.new()
	var spawn_sprite = Sprite.new()
	shield_sprite.texture = load("res://Assets/shieldFull.png")
	shield_sprite.scale = Vector2(1.5,1.5)
	shield_sprite.position = Vector2(1882,1900)
	shield_sprite.set_name("shield_sprite")
	spawn_sprite.texture = load("res://Assets/shield_spawn.png")
	spawn_sprite.scale = Vector2(4,4)
	spawn_sprite.position = Vector2(1882,1900)
	spawn_sprite.set_name("shield_spawn")
	add_child(_shield_spawn)
	_shield_spawn.add_child(col_2d)
	#add_child_below_node(shield_spawn,col_2d)
	add_child_below_node(_shield_spawn,shield_sprite)
	add_child_below_node(_shield_spawn,spawn_sprite)
	_shield_spawn.connect("area_entered",self,"give_shield")

"""
/*
* @pre Called when a player grabs a shield from spawn
* @post give player shield and let server know its taken
* @param area
* @return None
*/
"""
func give_shield(area):
	if area.is_in_group("player") and _shield_available:
		ServerConnection.send_shield_notif()
		_shield_available = false
		main_player.shield.giveShield()
		get_node("shield_sprite").hide()
		start_shield_timer()

"""
/*
* @pre Called when server says someone stepped on shield
* @post Shield becomes unavailable for a time period
* @param p_id -> int (player who stepped on it)
*		 shield_num -> int (which spawn it was)
* @return None
*/
"""
func someone_took_shild(player_id,_shield_num):
	_shield_available = false
	get_node("shield_sprite").hide()
	start_shield_timer()
	for o_player in server_players:
		if player_id == o_player.get('num'):
			o_player.get('player_obj').shield.giveShield()
			break

"""
/*
* @pre Shield was stepped on
* @post start timer to respawn shield when done
* @param None
* @return None
*/
"""
func start_shield_timer():
	var s_tmr: Timer = Timer.new()
	add_child(s_tmr)
	s_tmr.wait_time = 15
	s_tmr.one_shot = true
	s_tmr.start()
	# warning-ignore:return_value_discarded
	s_tmr.connect("timeout",self, "_respawn_shield", [s_tmr])

"""
/*
* @pre Timer went off
* @post respawn the shield
* @param tmr (timer to get rid of)
* @return None
*/
"""
func _respawn_shield(tmr:Timer):
	tmr.queue_free()
	_shield_available = true
	get_node("shield_sprite").show()

"""
/*
* @pre Someone got hit by a sword
* @post move them to right position
* @param player_id -> int (id of player)
* 		 x -> int (x position to go to)
*		 y -> int (y position to go to)
* @return None
*/
"""
func someone_got_booped(player_id: int, x: int, y: int):
	for o_player in server_players:
		if player_id == o_player.get('num'):
			o_player.get('player_obj').was_booped(Vector2(x,y))
			break
