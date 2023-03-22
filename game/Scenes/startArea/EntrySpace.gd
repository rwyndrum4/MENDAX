"""
* Programmer Name - Freeman Spray, Ben Moeller
* Description - Code for controlling what happens in the entry space scene
* Date Created - 10/3/2022
* Date Revisions:
	10/8/2022 - Added the ability to go into settings from scene with enter key
	11/5/2022 - Added ability to transition to further minigames after the first
* Citations: https://godotengine.org/qa/33196/how-are-you-supposed-to-handle-null-objects
	for handling deleted tiles
"""

extends Control

# Member Variables
const CAVE_TIME = 90 #how much time players spend in the cave
var in_exit = false #variable to track if character is by the exit
var in_menu = false #variable to track if character is in options menu
var in_well = false #variable to track if character is by well
var steam_active = false #variable to tell if steam in passage is active
var stop_steam_control = false #variable to tell whether process function needs to check steam
var steam_modulate:float = 0 #modualte value that is gradually added to modulate of steam
var at_lever = false #variable to track if player is at the lever
var at_ladder = false #variable to track if player is at the ladder
var _shield_spawns: Array = [] #array that holds all shield objects
var _shields_available: Array = [] #array that holds if each shield is available or not
var _game_started = false #variable to tell if all players are in scene
var _enemies: Array = [] #Array of enemy objects
var dummyBoss
var _besier_arr: Array = [] #array to hold besiers for easy access
var server_players: Array = [] #array to hold all OTHER players in cave (not you)
var other_player = "res://Scenes/player/arena_player/arena_player.tscn" #class for other player's body objects
var imposter = preload("res://Scenes/Mobs/imposter.tscn") #imposter enemies class
var sword = null #sword for the player

# Scene Objects
onready var confuzzed = $Player/confuzzle
onready var instructions: Label = $exitCaveArea/exitDirections
onready var myTimer: Timer = $GUI/Timer
onready var timerText: Label = $GUI/Timer/timerText
onready var textBox = $GUI/textBox
onready var steamAnimations = $steamControl/steamAnimations
onready var secretPanel = $worldMap/Node2D_1/Wall3x3_6
onready var secretPanelCollider = $worldMap/Node2D_1/colliders/secretDoor
onready var ladder = $worldMap/Node2D_1/Ladder1x1
onready var pitfall = $worldMap/Node2D_1/Pitfall1x1_2
onready var player = $Player
onready var wellLabeled = $well/Label

"""
/*
* @pre Called when the node enters the scene tree for the first time.
* @post updates starts the timer
* @param None
* @return None
*/
"""
func _ready():
	player.set_physics_process(false)
	#hide cave instructions at start
	instructions.hide()
	$fogSprite.modulate.a8 = 0
	GlobalSignals.emit_signal("toggleHotbar", true)
	wellLabeled.visible = false
	# warning-ignore:return_value_discarded
	GlobalSignals.connect("openChatbox", self, "chatbox_use")
	# warning-ignore:return_value_discarded
	Global.connect("all_players_arrived", self, "_can_start_game")
	# warning-ignore:return_value_discarded
	ServerConnection.connect("minigame_can_start", self, "_can_start_game_other")
	#Spawn the players if a match is ongoing
	if ServerConnection.match_exists() and ServerConnection.get_server_status():
		ServerConnection.send_spawn_notif()
		spawn_players()
		if ServerConnection._player_num == 1:
			#in case p1 is last player to get to minigame
			if Global.get_minigame_players() == Global.get_num_players() - 1:
				ServerConnection.send_minigame_can_start()
				_game_started = true
				start_cave()
		else:
			#Set a five second timer to wait for other players to spawn in
			var wait_for_start: Timer = Timer.new()
			add_child(wait_for_start)
			wait_for_start.wait_time = 5
			wait_for_start.one_shot = true
			wait_for_start.start()
			# warning-ignore:return_value_discarded
			wait_for_start.connect("timeout",self, "_start_timer_expired", [wait_for_start])
	#Start cave scene if single player
	else:
		start_cave()

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
	if not stop_steam_control:
		control_steam()
	# Check for completion of boss stage 1
	if Global.progress == 4:
		#besier tracker not needed anymore
		ServerConnection.disconnect("final_boss_besier_lit", self, "_besier_was_lit")
		Global.state = Global.scenes.DILEMMA
	if Global.progress == 5:
		load_boss(2)
	if Global.progress == 6 or Global.progress == 8:
		if sword.direction == "right":
			sword.get_node("pivot").position = $Player.position + Vector2(60,0)
		elif sword.direction == "left":
			sword.get_node("pivot").position = $Player.position + Vector2(-60,0)
	if Global.progress == 7:
		load_boss(3)
	if player.isInverted == true:
		confuzzed.visible = true
	else:
		confuzzed.visible = false

"""
/*
* @pre An input of any sort
* @post None
* @param Takes in an event
* @return None
*/
"""
func _input(_ev):
	if in_well:
		if Input.is_action_just_pressed("ui_press_e",false) and dummyBoss.get_vulnerable_status():
			dummyBoss._set_invulnerability(false)
			ServerConnection.send_boss_vulnerability()
			var wait_for_start: Timer = Timer.new()
			add_child(wait_for_start)
			wait_for_start.wait_time = 20
			wait_for_start.one_shot = true
			wait_for_start.start()
			# warning-ignore:return_value_discarded
			wait_for_start.connect("timeout",self, "_shield_up_boss",[wait_for_start])
	if in_exit:
		if Input.is_action_just_pressed("ui_accept",false) and not Input.is_action_just_pressed("ui_enter_chat"):
			# warning-ignore:return_value_discarded
			Global.state = Global.scenes.MAIN_MENU #change scene to main menu
	if at_lever:
		if Input.is_action_just_pressed("ui_accept",false) and not Input.is_action_just_pressed("ui_enter_chat"):
			if is_instance_valid(secretPanel):
				secretPanel.queue_free()
			if is_instance_valid(secretPanelCollider):
				secretPanelCollider.queue_free()
	if at_ladder:
		if Input.is_action_just_pressed("ui_accept",false) and not Input.is_action_just_pressed("ui_enter_chat"):
			ladder.texture = $root/Assets/tiles/TilesCorrected/WallTile_Tilt_Horiz
	#DEBUG PURPOSES - REMOVE FOR FINAL GAME!!!
	#IF YOU PRESS P -> TIMER WILL REDUCE TO 3 SECONDS
	if Input.is_action_just_pressed("timer_debug_key",false):
		myTimer.start(3)
	#IF YOU PRESS O (capital 'o') -> TIMER WILL INCREASE TO ARBITRARILY MANY SECONDS
	if Input.is_action_just_pressed("minigame_debug_key",false):
		Global.minigame = Global.minigame + 1
	#IF YOU PRESS Q -> MINIGAME COUNTER WILL INCREASE BY 1 (1 press at start will set next to Arena, > 1 will prevent minigame from loading
	if Input.is_action_just_pressed("extend_timer_debug_key",false):
		if Global.minigame > 2:
			Global.progress = 4
			Global.state = Global.scenes.DILEMMA
		myTimer.start(30000)

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
	if not _game_started:
		_game_started = true
		start_cave()

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
	_game_started = true
	ServerConnection.send_minigame_can_start()
	start_cave()

"""
/*
* @pre Called when non-player 1 player receives signal to start game
* @post starts the game if timer hasn't already done it for it
* @param None
* @return None
*/
"""
func _can_start_game_other():
	if not _game_started:
		_game_started = true
		start_cave()

"""
* @pre all conditions have been met to start cave section
* @post starts time and sets other variables
* @param None
* @return None
"""
func start_cave():
	player.set_physics_process(true)
	#Reset player trackers for next game
	Global.reset_minigame_players()
	#Hide waiting for players text
	$GUI/wait_on_players.hide()
	#Start timer
	myTimer.start(CAVE_TIME)

"""
* @post shows instructions on screen and sets in_cave to true
* @param _body -> body of the player
* @return None
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
	#change scene to riddler minigame
	if Global.minigame == 0:
		Global.minigame = 1
		Global.state = Global.scenes.RIDDLER_MINIGAME
	#change scene to arena minigame
	elif Global.minigame == 1:
		Global.minigame = 2
		Global.state = Global.scenes.ARENA_MINIGAME
	#change scene to rhythm minigame
	elif Global.minigame == 2:
		Global.minigame = 3
		Global.state = Global.scenes.RHYTHM_INTRO
	else: 
		load_boss(1)

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
* @pre Fog is enterred from the right side of the passage
* @post activates/deactivates steam based on side entered from
* @param _area -> Area2D node
* @return None
*/
"""
func _on_right_side_area_entered(area):
	if not area.is_in_group("player"):
		return
	var pos = $Player.position
	if pos.x > -1200.0:
		steam_area_activated()
	else:
		steam_area_deactivated()

"""
/*
* @pre Fog is enterred from the left side of the passage
* @post activates/deactivates steam based on side entered from
* @param _area -> Area2D node
* @return None
*/
"""
func _on_left_side_area_entered(area):
	if not area.is_in_group("player"):
		return
	var pos = $Player.position
	if pos.x < -5800:
		steam_area_activated()
	else:
		steam_area_deactivated()

"""
/*
* @pre None
* @post turns on and shows animations
* @param None
* @return None
*/
"""
func steam_area_activated():
	$fogSprite.show()
	steam_active = true
	stop_steam_control = false
	steam_modulate = 0.0
	for object in steamAnimations.get_children():
		object.frame = 0
		object.show()
		object.play("mist")

"""
/*
* @pre None
* @post turns off and hides animations
* @param None
* @return None
*/
"""
func steam_area_deactivated():
	steam_active = false
	for object in steamAnimations.get_children():
		object.hide()
		object.stop()

func spawn_players():
	#set initial position the players should be on spawn
	set_init_player_pos()
	#num_str is the player number (1,2,3,4)
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
* @post function to gradually make fog come into view
* @param None
* @return None
*/
"""
func control_steam():
	var fog_modulate = $fogSprite.modulate.a8
	if steam_active and fog_modulate != 128:
		steam_modulate += 0.5
		if int(steam_modulate) % 2 == 0:
			$fogSprite.modulate.a8 = steam_modulate
	elif not steam_active and fog_modulate != 0:
		steam_modulate -= 0.5
		if int(steam_modulate) % 2 == 0:
			$fogSprite.modulate.a8 = steam_modulate
	elif fog_modulate == 0 and not steam_active:
		$fogSprite.hide()
		stop_steam_control = true
		
"""	
* @pre Called when player enters the lever's Area2D zone
* @post sets at_lever to true (for interactability purposes)
* @param _body -> body of the player
* @return None
*/
"""
func _on_leverArea_body_entered(_body: PhysicsBody2D): #change to body if want to use
	at_lever = true

"""
/*
* @pre Called when player exits the lever's Area2D zone
* @post sets at_lever to false (for interactability purposes)
* @param _body -> body of the player
* @return None
*/
"""
func _on_leverArea_body_exited(_body: PhysicsBody2D): #change to body if want to use
	at_lever = false

"""
/*
* @pre Called when player enters the ladder's Area2D zone
* @post sets at_ladder to true (for interactability purposes)
* @param _body -> body of the player
* @return None
*/
"""
func _on_ladderArea_body_entered(_body: PhysicsBody2D): #change to body if want to use
	at_ladder = true

"""
/*
* @pre Called when player exits the ladder's Area2D zone
* @post sets at_ladder to false (for interactability purposes)
* @param _body -> body of the player
* @return None
*/
"""
func _on_ladderArea_body_exited(_body: PhysicsBody2D): #change to body if want to use
	at_ladder = false

"""
/*
* @pre Called when player enters the pitfall's Area2D zone
* @post replaces the tile with a pit (blank tile)
* @param _body -> body of the player
* @return None
*/
"""
func _on_pitfallArea_body_entered(_body: PhysicsBody2D): #change to body if want to use
	pitfall.texture = load("res://Assets/tiles/TilesCorrected/BlankTile.png")
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

"""
/*
* @pre Called by the timer after it reaches 0 when all minigames have been completed.
* @post begins the final boss fight
* @param None
* @return Currently, timer stops and four bezier objects spawn
*/
"""			
func load_boss(stage_num:int):
	myTimer.stop()
	var boss = preload("res://Scenes/FinalBoss/Boss.tscn").instance()
	_enemies.append(boss)
	# warning-ignore:return_value_discarded
	ServerConnection.connect("arena_enemy_hit",self,"_someone_hit_enemy")
	# warning-ignore:return_value_discarded
	ServerConnection.connect("arena_player_lost_health",self,"_other_player_hit")
	# warning-ignore:return_value_discarded
	ServerConnection.connect("arena_player_swung_sword",self,"_other_player_swung_sword")
	if stage_num == 1:
		ServerConnection.connect("final_boss_besier_lit", self, "_besier_was_lit")
		# Generate beziers
		var bez1 = preload("res://Scenes/FinalBoss/Bezier.tscn").instance()
		var bez2 = preload("res://Scenes/FinalBoss/Bezier.tscn").instance()
		var bez3 = preload("res://Scenes/FinalBoss/Bezier.tscn").instance()
		var bez4 = preload("res://Scenes/FinalBoss/Bezier.tscn").instance()
		_besier_arr = [bez1, bez2, bez3, bez4]
		# Assign ids (for the purpose of differentiating signals)
		bez1._id = 1
		bez2._id = 2
		bez3._id = 3
		bez4._id = 4
		# Place beziers
		bez1.set("position", Vector2(2750, 2000))
		bez2.set("position", Vector2(1500, 0))
		bez3.set("position", Vector2(-10000, 4000))
		bez4.set("position", Vector2(-7750, 3250))
		# Add beziers to scene
		add_child_below_node($Darkness, bez1)
		add_child_below_node($Darkness, bez2)
		add_child_below_node($Darkness, bez3)
		add_child_below_node($Darkness, bez4)
	if stage_num == 2:
		# Light up the cave
		$Darkness.hide()
		# Hide light from cave entrance
		$Light2D.hide()
		# Hide player torch light
		$Player.get_node("light/Torch1").hide()
		# Give player a sword
		sword = preload("res://Scenes/player/Sword/Sword.tscn").instance()
		sword.direction = "right"
		sword.get_node("pivot").position = $Player.position + Vector2(60,20)
		add_child_below_node($Player, sword)
		Global.progress = 6
		#imposter spawns
		var wait_for_start: Timer = Timer.new()
		add_child(wait_for_start)
		wait_for_start.wait_time = 5
		wait_for_start.one_shot = false
		wait_for_start.start()
		# warning-ignore:return_value_discarded
		wait_for_start.connect("timeout",self, "_imposter_spawn")
	if stage_num == 3:
		# Light up the cave
		$Darkness.hide()
		# Hide light from cave entrance
		$Light2D.hide()
		# Hide player torch light
		$Player.get_node("light/Torch1").hide()
		# Give player a sword
		sword = preload("res://Scenes/player/Sword/Sword.tscn").instance()
		sword.direction = "right"
		sword.get_node("pivot").position = $Player.position + Vector2(60,20)
		add_child_below_node($Player, sword)
		Global.progress = 8
		#spawn enemies from arena
		spawn_stage_three_enemies()
		#imposter spawns
		var wait_for_start: Timer = Timer.new()
		add_child(wait_for_start)
		wait_for_start.wait_time = 5
		wait_for_start.one_shot = false
		wait_for_start.start()
		# warning-ignore:return_value_discarded
		wait_for_start.connect("timeout",self, "_imposter_spawn")
		boss._set_invulnerability(true)
		dummyBoss = boss
	if stage_num > 1:
		#Unhide player health bar and set total health to 150
		$Player/ProgressBar.show()
		$Player/ProgressBar.value = 150
		spawn_shields() #shield spawns now show up in 3 places
	# Initialize, place, and spawn boss
	boss.set("position", Vector2(-4250, 2160))
	add_child_below_node($worldMap, boss)
	# Zoom out camera so player can view Mendax in all his glory
	$Player.get_node("Camera2D").set("zoom", Vector2(2, 2))

"""
/*
* @pre None
* @post Shield is spawned inside of game
* @param None
* @return None
*/
"""
func spawn_shields():
	# warning-ignore:return_value_discarded
	ServerConnection.connect("character_took_shield",self,"someone_took_shield")
	var shield_positions = [
		Vector2(-4000,3000), #In middle by boss
		Vector2(-7850, 5250), #In bottom left
		Vector2(750, 3000) #On the right side
	]
	var inc = 0
	for pos in shield_positions:
	# Generate shild spawn
		var shield_spawn = Area2D.new()
		var col_2d = CollisionShape2D.new()
		var shape = CircleShape2D.new()
		shape.set_radius(80)
		col_2d.set_shape(shape)
		shield_spawn.position = pos
		var shield_sprite = Sprite.new()
		var spawn_sprite = Sprite.new()
		shield_sprite.texture = load("res://Assets/shieldFull.png")
		shield_sprite.scale = Vector2(1.5,1.5)
		shield_sprite.position = pos
		shield_sprite.set_name("shield_sprite" + str(inc))
		spawn_sprite.texture = load("res://Assets/shield_spawn.png")
		spawn_sprite.scale = Vector2(4,4)
		spawn_sprite.position = pos
		add_child(shield_spawn)
		shield_spawn.add_child(col_2d)
		#add_child_below_node(shield_spawn,col_2d)
		add_child_below_node(shield_spawn,shield_sprite)
		add_child_below_node(shield_spawn,spawn_sprite)
		shield_spawn.connect("area_entered",self,"give_shield", [inc])
		_shield_spawns.append(shield_spawn)
		_shields_available.append(true)
		inc += 1

"""
/*
* @pre Called when a player grabs a shield from spawn
* @post give player shield and let server know its taken
* @param area
* @return None
*/
"""
func give_shield(area, s_id):
	if area.is_in_group("player") and _shields_available[s_id]:
		ServerConnection.send_shield_notif()
		_shields_available[s_id] = false
		player.shield.giveShield()
		get_node("shield_sprite" + str(s_id)).hide()
		start_shield_timer(s_id)

"""
/*
* @pre Shield was stepped on
* @post start timer to respawn shield when done
* @param None
* @return None
*/
"""
func start_shield_timer(shield_id):
	var s_tmr: Timer = Timer.new()
	add_child(s_tmr)
	s_tmr.wait_time = 15
	s_tmr.one_shot = true
	s_tmr.start()
	# warning-ignore:return_value_discarded
	s_tmr.connect("timeout",self, "_respawn_shield", [s_tmr, shield_id])

"""
* @pre Called when server says someone stepped on shield
* @post Shield becomes unavailable for a time period
* @param p_id -> int (player who stepped on it)
*		 shield_num -> int (which spawn it was)
* @return None
"""
func someone_took_shield(player_id,_shield_num):
	_shields_available[_shield_num] = false
	get_node("shield_sprite" + str(_shield_num)).hide()
	start_shield_timer(_shield_num)
	for o_player in server_players:
		if player_id == o_player.get('num'):
			o_player.get('player_obj').shield.giveShield()
			break

"""
/*
* @pre Timer went off
* @post respawn the shield
* @param tmr (timer to get rid of)
* @return None
*/
"""
func _respawn_shield(tmr:Timer, shield_id:int):
	tmr.queue_free()
	_shields_available[shield_id] = true
	get_node("shield_sprite" + str(shield_id)).show()

"""
/*
* @pre Called once start time expires (happens once)
* @post deletes timer and starts game if necessary
* @param timer -> Timer
* @return None
*/
"""
func _imposter_spawn():
	var new_imposter = imposter.instance()
	new_imposter.setup_pos(player.position)
	add_child(new_imposter)

"""
* @pre Stage 3 of final boss has started
* @post spawns extra enemies to make the stage harder
* @param None
* @return None
"""
func spawn_stage_three_enemies():
	var slow_enemy = load("res://Scenes/minigames/arena/littleGuy.tscn")
	var slow_en_proerties = [
		[Vector2(-6000,3000), 600, 3500],
		[Vector2(-500, 1000), 300, 6000],
		[Vector2(0, 3000), 500, 4500],
		[Vector2(-10000, 5000), 500, 4000],
		[Vector2(-8500, 3000), 400, 3800],
		[Vector2(-10000, 6200), 250, 3900],
	]
	for prop_arr in slow_en_proerties:
		var slow_en = slow_enemy.instance()
		slow_en.position = prop_arr[0]
		slow_en.set_max_dir(prop_arr[1])
		slow_en.ACCELERATION = prop_arr[2]
		add_child(slow_en)

func _on_well_body_entered(body):
	if Global.progress == 8:
		if "Player" in body.name:
			wellLabeled.visible = true
			in_well = true

func _on_well_body_exited(body):
	if Global.progress == 8:
		if "Player" in body.name:
			wellLabeled.visible = false
			in_well = false

func _shield_up_boss(timer):
	timer.queue_free()
	dummyBoss._set_invulnerability(true)

"""
* @pre Someone else lit up a besier
* @post light the besier and emit message
* @param who -> int (player num of who lit it)
* 		 besier_id -> int (id of besier lit)
* @return None
"""
func _besier_was_lit(who: int, besier_id: int):
	for bes in _besier_arr:
		if bes._id == besier_id:
			#if besier is already lit get out
			if bes._lit == 2:
				break
			#else light up besier
			bes._lit = 1
			bes.someone_lit_besier() #function to light it
			var who_did_it: String = Global.get_player_name(who)
			#Add message to chat on who did it
			GlobalSignals.emit_signal(
				"exportEventMessage",
				who_did_it + " lit up besier " + str(besier_id),
				"blue"
			)
			break

"""
* @pre Someone else hit an enemy
* @post lower the enemy's health
* @param enemy_id (id of enemy aka where to index)
*		 dmg_taken (amount of health to subtract)
*		 player_id (who hit the enemy)
*		 enemy_type (type of enemy represented as a String)
* @return None
"""
func _someone_hit_enemy(enemy_id: int, dmg_taken: int, _player_id: int,enemy_type:String):
	if enemy_type == "Boss":
		_enemies[enemy_id].take_damage_server(dmg_taken)

"""
/*
* @pre received update from server
* @post updates the health of player that was hit
* @param player_id -> int (id of player hit), player_health -> int (new health value)
* @return None
*/
"""
func _other_player_hit(player_id: int, player_health: int):
	for o_player in server_players:
		if player_id == o_player.get('num'):
			var p_obj = o_player.get('player_obj')
			if is_instance_valid(p_obj):
				p_obj.take_damage(player_health)
			Global.player_health[str(player_id)]=player_health
			break

"""
/*
* @pre received update from server
* @post game sets player who swung to swing their sword
* @param player_id -> int (number of player to be updated)
* @return None
*/
"""
func _other_player_swung_sword(player_id: int, direction: String):
	for o_player in server_players:
		if player_id == o_player.get('num'):
			o_player['sword_dir'] = direction
			o_player.get('player_obj').swing_sword(direction)
			break
