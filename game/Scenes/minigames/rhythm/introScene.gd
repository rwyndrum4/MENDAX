extends Node2D

var _wait_over = false #variable that tracks if done waiting for players
var onlinePlayer = preload("res://Scenes/player/idle_player/idle_player.tscn")

onready var textbox = $textBox
onready var player_one = $Player
onready var player_one_ani = $Player/position/animated_sprite
onready var torch = $Player/light

func _ready():
	#Player one configuration
	player_one.set_physics_process(false)
	player_one_ani.play("idle_blue")
	torch.hide()
	# warning-ignore:return_value_discarded
	Global.connect("all_players_arrived", self, "_can_start_game")
	# warning-ignore:return_value_discarded
	ServerConnection.connect("minigame_can_start", self, "_can_start_game_other")
	if ServerConnection.match_exists() and ServerConnection.get_server_status():
		spawn_players()
		ServerConnection.send_spawn_notif()
		if ServerConnection._player_num == 1:
			#in case p1 is last player to get to minigame
			if Global.get_minigame_players() == Global.get_num_players() - 1:
				ServerConnection.send_minigame_can_start()
				_wait_over = true
				transition_to_rhythm()
		else:
			var wait_for_start: Timer = Timer.new()
			add_child(wait_for_start)
			wait_for_start.wait_time = Global.WAIT_FOR_PLAYERS_TIME
			wait_for_start.one_shot = true
			wait_for_start.start()
			# warning-ignore:return_value_discarded
			wait_for_start.connect("timeout",self, "_start_timer_expired", [wait_for_start])
	#else if single player game
	else:
		_wait_over = true
		transition_to_rhythm()

"""
* @pre Called once start time expires (happens once)
* @post deletes timer and starts game if necessary
* @param timer -> Timer
* @return None
"""
func _start_timer_expired(timer):
	timer.queue_free()
	if not _wait_over:
		_wait_over = true
		transition_to_rhythm()

"""
* @pre Called once all players have spawned into the minigame
* 	only run by PLAYER 1
* @post sends signal to other players to start, and start game
* @param None
* @return None
"""
func _can_start_game():
	_wait_over = true
	ServerConnection.send_minigame_can_start()
	transition_to_rhythm()

"""
* @pre Called when non-player 1 player receives signal to start game
* @post starts the game if timer hasn't already done it for it
* @param None
* @return None
"""
func _can_start_game_other():
	if not _wait_over:
		_wait_over = true
		transition_to_rhythm()

"""
* @pre all players have joined and text has finished playing
* @post changes scenes from this to actual rhythm game
* @param None
* @return None
"""
func transition_to_rhythm():
	$GUI/wait_on_players.hide()
	Global.reset_minigame_players()
	# warning-ignore:return_value_discarded
	GlobalSignals.connect("textbox_empty",self,"_dialogue_over")
	play_dialogue()

"""
* @pre dialogue has finished playing
* @post transition to next scene
* @param None
* @return None
"""
func _dialogue_over():
	var t = Timer.new()
	t.wait_time = 1
	t.one_shot = true
	add_child(t)
	t.start()
	yield(t, "timeout")
	t.queue_free()
	Global.state = Global.scenes.RHYTHM_MINIGAME

"""
* @pre all players have joined and text has finished playing
* @post changes scenes from this to actual rhythm game
* @param None
* @return None
"""
func play_dialogue():
	textbox.queue_text("You have done well to make it this far")
	var var_text = "face off in" if ServerConnection.match_exists() else "play"
	textbox.queue_text("Your next challenge will be to " + var_text + " a rhyhtm game")
	textbox.queue_text("Why a rhythm game in a game inside of a cave you might be wondering")
	textbox.queue_text("I don't know either, but good luck")

"""
* @pre their is an online game going on
* @post spawns other players and changes main player
* @param None
* @return None
"""
func spawn_players():
	#num_str -> player number (1,2,3,4)
	for num_str in Global.player_positions:
		#Add animated player to scene
		var num = int(num_str)
		var p_pos: Vector2 = get_pos(num)
		#if player is YOUR player (aka player you control)
		if num == ServerConnection._player_num:
			player_one.position = p_pos
			$Player/Camera2D.offset = get_camera_offset(num)
			player_one.set_color(num)
			var ani = "idle_" + Global.player_colors[num]
			player_one_ani.play(ani)
		#if the player is another online player
		else:
			var new_player = onlinePlayer.instance()
			#Change size and pos of sprite
			new_player.position = p_pos
			new_player.scale *= 4
			#Add child to the scene
			add_child(new_player)
			var ani = Global.player_colors[num] + "_idle"
			new_player.play_animation(ani)

"""
* @pre None
* @post says what a players position is depending on player number
* @param p_num -> int (player num)
* @return Vector2 corresponding to a player pos
"""
func get_pos(p_num: int) -> Vector2:
	match p_num:
		1: return Vector2(1500,500)
		2: return Vector2(1500, 750)
		3: return Vector2(2300,500)
		4: return Vector2(2300, 750)
		_: return Vector2.ZERO

"""
* @pre None
* @post says what a players camera offset should be
* @param p_num -> int (player num)
* @return Vector2 corresponding to a player pos
"""
func get_camera_offset(p_num: int) -> Vector2:
	match p_num:
		1: return Vector2(400,100)
		2: return Vector2(400,-150)
		3: return Vector2(-400,100)
		4: return Vector2(-400, -150)
		_: return Vector2.ZERO
