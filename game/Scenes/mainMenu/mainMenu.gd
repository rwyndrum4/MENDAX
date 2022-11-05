"""
* Programmer Name - Ben Moeller, Freeman Spray, Jason Truong, Mohit Garg, Will Wyndrum
* Description - File for controlling the what happens with actions within the main menu
* Date Created - 9/16/2022
* Date Revisions:
	9/17/2022 - Added options menu functionality
	9/18/2022 - Added join code functionality
	9/21/2022 - Fixing issue with fps label not working correctly
	10/1/2022 - Added the ability to move with keyboard in settings menu
	10/1/2022 - Fixed options menu movment
	11/4/2022 - Adding server functionality 
"""
extends Control

# Member Variables
onready var startButton = $menuButtons/Start
onready var code_line_edit = $joinLobby/enterLobbyCode

#### Variables for showing players on rocks ###
#array for holding player objects that are created
var player_objects: Array = [] 
#value to scale up animated sprites
const SCALE_VAL: int = 5 
#scene that holds the idle player animation
var idle_player = "res://Scenes/player/idle_player/idle_player.tscn"
#array that holds the animation names
var animation_names: Array = ["blue_idle","red_idle","green_idle","orange_idle"]
#current number of players in menu
var num_players: int = 0
#max players allowed
const MAX_PLAYERS: int = 4

### Member Variables ###
#popup that is displayed when creating a new game
var game_init_popup:AcceptDialog
#popup that is displayed need to get user's username
var get_user_input:AcceptDialog
#bool to let menu know if player is typing code
var typing_code: bool = false

"""
/*
* @pre called when main menu is loaded in (run once)
* @post runs preliminary code to help user functionality
* @param None
* @return None
*/
"""
func _ready():
	initialize_menu()
	# warning-ignore:return_value_discarded
	ServerConnection.connect("character_spawned",self,"spawn_character")

"""
/*
* @pre called for every frame inside of the game
* @post detects user input
* @param delta -> float (time)
* @return None
*/
"""
func _process(_delta): #if you want to use delta, then change it to delta
	if typing_code and Input.is_action_just_pressed("ui_cancel"):
		startButton.grab_focus()
		code_line_edit.hide()
	if Input.is_action_just_pressed("ui_cancel"):
		startButton.grab_focus()

"""
/*
* @pre Start Button is pressed
* @post Scene change to start of game
* @param None
* @return None
*/
"""
func _on_Start_pressed():
	#delete player objects
	for player in player_objects:
		despawn_player(player['player_obj'])
	#change scene to start area
	SceneTrans.change_scene(Global.scenes.START_AREA)

"""
/*
* @pre Options Button is pressed
* @post Scene change to options menu
* @param None
* @return None
* @knownFaults pop-up size and location depends not only on whether the screen is windowed or fullscreen,
*   but also whether the market has been entered in the current iteration of the game
* @knownFaults animated fire does not anchor to its position when the screen is adjusted
*/
"""
func _on_Options_pressed():
	Global.state = Global.scenes.OPTIONS_FROM_MAIN

"""
/*
* @pre Market Button is pressed
* @post Scene change to store scene
* @param None
* @return None
* @knownFaults resets join code to default (XXXX)
*/
"""
#When button pressed switches to Store scene
func _on_Market_pressed():
	Global.state = Global.scenes.MARKET

"""
/*
* @pre Tests Button is pressed
* @post not yet implemented
* @param None
* @return None
*/
"""
func _on_Tests_pressed():
	pass # Replace with function body.

"""
/*
* @pre Quit Button is pressed
* @post Application is closed
* @param None
* @return None
*/
"""
func _on_Quit_pressed():
	get_tree().quit()

"""
/*
* @pre "Get Code" Button is pressed
* @post Generate and display string of four random letters in the "code" RichTextLabel
* @param None
* @return None
*/
"""
func generate_random_code() -> String:
	var letters = ['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 
				   'J', 'K', 'L', 'M', 'N', 'O', 'P', 'Q', 'R', 
				   'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z',]
	var rng = RandomNumberGenerator.new()
	var index1 = getRandAlphInd(rng)
	var index2 = getRandAlphInd(rng)
	var index3 = getRandAlphInd(rng)
	var index4 = getRandAlphInd(rng)
	return letters[index1] + letters[index2] + letters[index3] + letters[index4]
	
"""
/*
* @pre Helper function to _on_GetCode_button_up(). Only called within the context of the function
* @post Generate a random number between 1 and 26 (inclusive)
* @param rng, a RandomNumberGenerator class object
* @return randomAlphabetIndex, the random number generated using rng.
*/
"""
func getRandAlphInd(rng):
		rng.randomize()
		var randomAlphabetIndex = rng.randi_range(0, 25)
		return randomAlphabetIndex

"""
/*
* @pre Called in ready func
* @post Initialize necessary components in menu
* @param None
* @return None
*/
"""
func initialize_menu():
	#Grab focus on start button so keys can be used to navigate buttons
	startButton.grab_focus()
	#check if there is a username
	if Save.game_data.username == "":
		var win_text = "Welcome to Mendax!"
		var d_text = "Username required!\nPlease enter username:\n"
		d_text += "(Single word, you can change it afterward in settings)"
		create_get_user_window(win_text,d_text)

"""
/*
* @pre called when received that you have spawned back from server
* @post loads your player and all other players into scene
* @param player_name -> String
* @return None
*/
"""
func spawn_character(player_name:String):
	#Only allow 4 players
	if num_players == MAX_PLAYERS:
		return
	#Add animated player to scene
	var char_pos = get_char_pos(len(player_objects))
	var spawned_player = create_spawn_player(char_pos,player_name)
	#Add data to array
	player_objects.append({
		'player_obj': spawned_player
	})
	Global.player_positions.append({
		'id': num_players+1,
		'pos': Vector2(char_pos.x*5,char_pos.y*5)
	})
	num_players += 1

"""
/*
* @pre called when create game button is pressed
* @post creates a game code and joins the game
* @param None
* @return None
*/
"""
func _on_createGameButton_pressed():
	var code: String = generate_random_code()
	game_init_popup = AcceptDialog.new()
	if not ServerConnection.get_server_status():
		create_game_init_window(
			"Server not available",
			"Multiplayer not available, you are not connected to a game"
		)
	else:
		if ServerConnection.match_exists():
			create_game_init_window(
				"Game already exists!",
				"Please use the game code you already have"
			)
			return
		var current_players = yield(ServerConnection.create_match(code), "completed")
		create_game_init_window(
			"New game created!",
			"Your code is: " + code + "\nPlease share it with your friends!"
		)
		print("current players: ", current_players)
		#Add your user to scene
		#spawn_character(Save.game_data.username)
		$showLobbyCode/code.text = code

"""
/*
* @pre called when joinGame button is pressed
* @post shows the input field to enter match code
* @param None
* @return None
*/
"""
func _on_joinGame_pressed():
	code_line_edit.show()
	code_line_edit.grab_focus()
	code_line_edit.placeholder_text = "Enter Lobby Code Here"

"""
/*
* @pre called when focus of typing code is entered
* @post sets typing code to true (used in process func)
* @param None
* @return None
*/
"""
func _on_enterLobbyCode_focus_entered():
	typing_code = true

"""
/*
* @pre whenver the match code is entered
* @post if code is valid, joins the given match, displays error otherwise
* @param None
* @return None
*/
"""
func _on_enterLobbyCode_text_entered(new_text):
	var match_code = new_text.to_upper()
	if len(match_code) != 4:
		create_game_init_window(
			"Invalid code",
			"Please enter an alphabetical code with a length of 4"
		)
	else:
		if ServerConnection.get_server_status():
			if ServerConnection.match_exists():
				yield(ServerConnection.leave_match(ServerConnection._match_id), "completed")
			var users_in_menu = yield(ServerConnection.join_match(Global.current_matches[match_code]), "completed")
			#Spawn users that are currently in game and you
			for user in users_in_menu:
				spawn_character(user.username)
			$showLobbyCode/code.text = match_code
			create_game_init_window(
				"Joined match " + match_code,
				"Start the game with your friends when you want"
			)
		else:
			create_game_init_window(
				"Server not available",
				"Multiplayer not available, you are not connected to a game"
			)
			code_line_edit.text = ""
			code_line_edit.hide()

"""
/*
* @pre called when server notices a player has left
* @post deletes player from the scene
* @param 
* @return None
*/
"""
func despawn_player(player:AnimatedSprite):
	player.queue_free()

"""
/*
* @pre None
* @post returns Vector2 of where a character position should be 
* @param sizeof_arr -> int
* @return Vector2
*/
"""
func get_char_pos(sizeof_arr: int) -> Vector2:
	var result: Vector2 = Vector2.ZERO
	if sizeof_arr == 0:
		result.x = 150
		result.y = 65
	elif sizeof_arr == 1:
		result.x = 215
		result.y = 65
	elif sizeof_arr == 2:
		result.x = 150
		result.y = 120
	elif sizeof_arr == 3:
		result.x = 215
		result.y = 120
	return result

"""
/*
* @pre None
* @post creates the acceptDialog for getting player's username
* @param window_text -> String, dialog_text -> String
* @return None
*/
"""
func create_get_user_window(window_text, dialog_text):
	get_user_input = AcceptDialog.new()
	get_user_input.window_title = window_text
	get_user_input.dialog_text = dialog_text
	get_user_input.dialog_autowrap = true
	get_user_input.rect_min_size = Vector2(250,220)
	# warning-ignore:return_value_discarded
	get_user_input.connect("confirmed",self,"_delete_get_user_input_obj")
	var input_field = LineEdit.new()
	input_field.rect_min_size = Vector2(30,20)
	get_user_input.add_child(input_field)
	add_child(get_user_input)
	get_user_input.popup()

"""
/*
* @pre None
* @post creates the acceptDialog for setting game_init_obj
* @param window_text -> String, dialog_text -> String
* @return None
*/
"""
func create_game_init_window(window_text,dialog_text):
	game_init_popup = AcceptDialog.new()
	game_init_popup.window_title = window_text
	game_init_popup.dialog_text = dialog_text
	# warning-ignore:return_value_discarded
	game_init_popup.connect("confirmed",self,"_delete_game_init_obj")
	add_child(game_init_popup)
	game_init_popup.popup_centered()

"""
/*
* @pre None
* @post creates players that show up on rocks
* @param char_pos -> Vector2, player_name -> String
* @return None
*/
"""
func create_spawn_player(char_pos:Vector2, player_name:String) -> AnimatedSprite:
	var spawned_player:AnimatedSprite = load(idle_player).instance()
	#Change size and pos of sprite
	spawned_player.offset = char_pos
	spawned_player.scale = Vector2(SCALE_VAL,SCALE_VAL)
	spawned_player.play_animation(animation_names[num_players])
	#Add child to the scene
	add_child(spawned_player)
	#Create text and add it as a child of the new player obj
	var player_title: Label = Label.new()
	player_title.text = player_name
	player_title.rect_position = Vector2(
		(char_pos.x*SCALE_VAL)-(5*SCALE_VAL), 
		(char_pos.y*SCALE_VAL)-(20*SCALE_VAL)
	)
	player_title.add_font_override("font",load("res://Assets/ARIALBD.TTF"))
	add_child_below_node(spawned_player,player_title)
	return spawned_player

"""
/*
* @pre None
* @post deltes the game_init_popup object
* @param None
* @return None
*/
"""
func _delete_game_init_obj():
	game_init_popup.queue_free()
	startButton.grab_focus()

"""
/*
* @pre None
* @post deltes the get_user_input object and sends username data to settings
* @param None
* @return None
*/
"""
func _delete_get_user_input_obj():
	#get username from the LineEdit
	var given_username = get_user_input.get_child(3).text
	get_user_input.queue_free()
	if " " in given_username:
		var win_text = "Invalid username, please try again"
		var d_text = "Username can be one word, no spaces"
		create_get_user_window(win_text, d_text)
	else:
		GlobalSettings.update_username(given_username)
		startButton.grab_focus()
