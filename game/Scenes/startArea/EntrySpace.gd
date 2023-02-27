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
var in_exit = false
var in_menu = false
var steam_active = false #variable to tell if steam in passage is active
var stop_steam_control = false #variable to tell whether process function needs to check steam
var steam_modulate:float = 0 #modualte value that is gradually added to modulate of steam
var at_lever = false
var at_ladder = false
var imposter =preload("res://Scenes/Mobs/imposter.tscn")
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
	$fogSprite.modulate.a8 = 0
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
	timerText.text = convert_time(myTimer.time_left)
	if not stop_steam_control:
		control_steam()
	# Check for completion of boss stage 1
	if Global.progress == 4:
		Global.state = Global.scenes.DILEMMA
	if Global.progress == 5:
		load_boss(2)
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
		Global.state = Global.scenes.RHYTHM_MINIGAME
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
	if ServerConnection.match_exists() and ServerConnection.get_server_status():
		if area.get_parent().player_color != Global.player_colors[ServerConnection._player_num]:
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
	if ServerConnection.match_exists() and ServerConnection.get_server_status():
		if area.get_parent().player_color != Global.player_colors[ServerConnection._player_num]:
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
	if stage_num == 1:
		# Generate beziers
		var bez1 = preload("res://Scenes/FinalBoss/Bezier.tscn").instance()
		var bez2 = preload("res://Scenes/FinalBoss/Bezier.tscn").instance()
		var bez3 = preload("res://Scenes/FinalBoss/Bezier.tscn").instance()
		var bez4 = preload("res://Scenes/FinalBoss/Bezier.tscn").instance()
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
		$Player.get_node("Torch1").hide()
		Global.progress = 6
		#imposter spawns
		var wait_for_start: Timer = Timer.new()
		add_child(wait_for_start)
		wait_for_start.wait_time = 5
		wait_for_start.one_shot = false
		wait_for_start.start()
		# warning-ignore:return_value_discarded
		wait_for_start.connect("timeout",self, "_imposter_spawn")
		
	# Initialize, place, and spawn boss
	
	boss.set("position", Vector2(-4250, 2160))
	add_child_below_node($worldMap, boss)
	# Zoom out camera so player can view Mendax in all his glory
	$Player.get_node("Camera2D").set("zoom", Vector2(2, 2))
	
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
	new_imposter.position = Vector2(0, 3000)
	add_child(new_imposter)
