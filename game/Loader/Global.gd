"""
* Programmer Name - Jason Truong, Benjamin Moeller
* Description - File for global variables such as health, money, and etc.
* Date Created - 9/16/2022
* Date Revisions:
	- 10/22/2022: Added functionality for tracking scene changes
	- 11/11/2022: Added ability for Global to track player input state
"""
extends Node

# Player's balance
var money: int = 0
var powerup = "default"
var player_inventory = preload("res://Inventory/Inventory.tscn").instance()
var hotbar = preload("res://Inventory/Hotbar.tscn").instance()

# place to track where player should go when they exit the shop
var lastPos = "mainMenu"

#Entry First Time
var in_anim: int = 0
#variable to track what frame user was on after pressing start
var stars_last_frame = 0 

#track minigame
var minigame: int = 0
var players_in_minigame: int = 0

# Counter tracking progression in final boss fight
var progress = 0
var _in_final_boss = false

# Variable to track where boss can teleport in final boss
var _boss_tp_counter = 0
var _first_time_in_boss = false
var riddle_answer = ""
var rhythm_winner = ""

# Track if player died in the final boss
var _player_died_final_boss = false

# Variable for tracking how long you wait for players to load
const WAIT_FOR_PLAYERS_TIME = 30

# Signals
signal all_players_arrived()

"""
-----------------------------SCENE LOADER INSTRUCTION-------------------------------------
- state -> this is the variable that tracks what scene the game is currently in
- You set state to one of the enum states defined in scenes
- For example, if you want to change scene to main menu:
  Global.state = Global.scenes.MAIN_MENU
- The scene will only change if the process function in Scenes/globalScope/globalScope.gd
  detects that there has been a change in scene
- The paths for all the scenes are also defined in Scenes/globalScope/globalScope.gd
------------------------------------------------------------------------------------------
"""
# Current scene
var state = null
# Scenes that the game can switch to
enum scenes {
	MAIN_MENU,
	OPTIONS_FROM_MAIN,
	MARKET,
	CREDITS,
	START_AREA,
	CAVE,
	RIDDLER_MINIGAME,
	ARENA_MINIGAME,
	RHYTHM_INTRO,
	RHYTHM_MINIGAME,
	GAMEOVER,
	QUIZ,
	DILEMMA,
	END_SCREEN,
	TUTORIAL
}

# Hold dictionary mapping player num to name
# Ex. {"1": "Bob", "2": Mary, ...}
var player_names: Dictionary = {}
# Hold dictionary of player positions
# Ex. {"1": Vector2(44,70), "2": Vector2(0,5) ...}
var player_positions:Dictionary = {}
# Hold dictionary of player input vectors
var player_input_vectors:Dictionary = {}
# Hold current matches, for joining matches
# Example: "random_match_code": [nakama_code, group_chat_code]
var current_matches: Dictionary = {}
#keeps track of damage dealt to skeleton for each player
var skeleton_damage: Dictionary = {"1":0,"2":0,"3":0,"4":0}
#keeps track of health of each player
var player_health: Dictionary ={"1":0,"2":0,"3":0,"4":0}
#keeps track of damage dealt to chandelier for each player
var chandelier_damage: Dictionary = {"1":0,"2":0,"3":0,"4":0}
#keeps track of damage dealt to bod for each player
var bod_damage: Dictionary = {"1":0,"2":0,"3":0,"4":0}
#Dictionary that stores how player colors are distributed
var player_colors: Dictionary = {1:"blue",2:"red",3:"green",4:"orange"}
#Dictionary to track how many good notes each player hit in minigame
var player_good_notes:Dictionary = {}

"""
/*
* @pre function that is played on game load (once)
* @post connects relevant signals
* @param None
* @return None
*/
"""
func _ready():
	# warning-ignore:return_value_discarded
	ServerConnection.connect("state_updated",self,"_player_positions_updated")
	# warning-ignore:return_value_discarded
	ServerConnection.connect("input_updated",self,"_player_input_updated")
	# warning-ignore:return_value_discarded
	ServerConnection.connect("minigame_player_spawned",self, "_minigame_player_spawn")
	# warning-ignore:return_value_discarded
	ServerConnection.connect("good_notes_hit", self, "_rhythm_goods_hit")

"""
/*
* @pre None
* @post adds a match to the current_matches variable
* @param lobby_name -> String, match_id -> String, private_chat_id -> String
* @return None
*/
"""
func add_match(lobby_name:String,match_id:String,private_chat_id:String):
	#adds to dictionary
	current_matches[lobby_name] = [match_id, private_chat_id]

"""
/*
* @pre None
* @post returns player name dependent on what number they are
* @param player_num -> int (number player was assigned)
* @return String
*/
"""
func get_player_name(player_num: int) -> String:
	return player_names[str(player_num)]

"""
/*
* @pre None
* @post returns player number dependent on what name they have
* @param p_num -> String (name of player)
* @return int
*/
"""
func get_player_num(p_name: String) -> int:
	for p in player_names.keys():
		if player_names[p] == p_name:
			return int(p)
	return ERR_BUG
"""
/*
* @pre None
* @post returns a match from current_matches
* @param lobby_name -> String
* @return String
*/
"""
func get_match(lobby_name:String) -> String:
	#returns the really long match id
	return current_matches[lobby_name][0]

"""
/*
* @pre None
* @post returns the group chat id for the match needed
* @param lobby_name -> String
* @return String
*/
"""
func get_match_group_id(lobby_name: String) -> String:
	return current_matches[lobby_name][1]

"""
/*
* @pre None
* @post removes match from match pool
* @param lobby_name -> String
* @return None
*/
"""
func remove_match(lobby_name: String):
	# warning-ignore:return_value_discarded
	current_matches.erase(lobby_name)

"""
/*
* @pre None
* @post returns whether the current match exists in the match list or not
* @param player_code -> String
* @return bool
*/
"""
func match_exists(player_code:String) -> bool:
	#has = dictionary function that returns true if player_code is a key in current_matches
	return current_matches.has(player_code)

"""
/*
* @pre None
* @post returns the position of a given character
* @param player_id -> int
* @return Vector2
*/
"""
func get_player_pos(player_id:int) -> Vector2:
	#returns a Vector2 containing player pos ---> {x,y}
	return player_positions[str(player_id)]

"""
/*
* @pre None
* @post returns the input vector of a given character
* @param player_id -> int
* @return Vector2
*/
"""
func get_player_input_vec(player_id:int) -> Vector2:
	#returns a Vector2 containing player pos ---> {x,y}
	return player_input_vectors[str(player_id)]

"""
/*
* @pre None
* @post returns number of players in the game
* @param None
* @return int (number of current players)
*/
"""
func get_num_players() -> int:
	return len(player_positions)

"""
/*
* @pre None
* @post returns number of players in the minigame
* @param None
* @return None
*/
"""
func get_minigame_players() -> int:
	return players_in_minigame

"""
/*
* @pre None
* @post adds a player to the global var
* @param None
* @return None
*/
"""
func increment_minigame_player():
	players_in_minigame += 1

"""
/*
* @pre None
* @post resets player counter to 0
* @param None
* @return None
*/
"""
func reset_minigame_players():
	players_in_minigame = 0

"""
/*
* @pre None
* @post resets player counter to 0
* @param None
* @return None
*/
"""
func _minigame_player_spawn(_id: int):
	players_in_minigame += 1
	if players_in_minigame == get_num_players() - 1:
		if ServerConnection._player_num == 1:
			emit_signal("all_players_arrived")

"""
/*
* @pre None
* @post update a players position for a given id (their player number)
* @param id -> int, position -> vector 2
* @return None
*/
"""
func _player_positions_updated(id:int, position:Vector2):
	player_positions[str(id)] = position

"""
/*
* @pre None
* @post update a players current input
* @param id -> int, vec -> Vector2
* @return None
*/
"""
func _player_input_updated(id:int, vec:Vector2):
	player_input_vectors[str(id)] = vec

"""
/*
* @pre A player has left the game (just used in mainMenu right now)
* @post removes the player from lists tracking players
* @param p_name (name of the player that left)
* @return None
*/
"""
func remove_player_from_match(p_name:String) -> void:
	#Code to fix the player_names dictionary
	var found_desserter: bool = false
	var desserter_value: String = ""
	for p_num_str in player_names:
		if found_desserter:
			var save_name = player_names[p_num_str]
			var to_int = int(p_num_str)
			var new_num_str = str(to_int - 1)
			# warning-ignore:return_value_discarded
			player_names.erase(p_num_str)
			player_names[new_num_str] = save_name
		elif player_names[p_num_str] == p_name:
			found_desserter = true
			desserter_value = p_num_str
			# warning-ignore:return_value_discarded
			player_names.erase(p_num_str)
	#Code to fix the player_positions dictionary
	found_desserter = false
	var last_pos = Vector2.ZERO
	for p_num_str in player_positions:
		if found_desserter:
			var tmp = player_positions[p_num_str]
			var to_int = int(p_num_str)
			var new_num_str = str(to_int - 1)
			# warning-ignore:return_value_discarded
			player_positions.erase(p_num_str)
			player_names[new_num_str] = last_pos
			last_pos = tmp
		elif p_num_str == desserter_value:
			found_desserter = true
			last_pos = player_positions[p_num_str]
			# warning-ignore:return_value_discarded
			player_positions.erase(p_num_str)

"""
/*
* @pre Rhythm game finished
* @post sets how many good notes each player hit
* @param p_id (layer_id), num_goods (number good notes hit)
* @return None
*/
"""
func _rhythm_goods_hit(p_id: int, num_goods:int):
	player_good_notes[p_id] = num_goods

"""
/*
* @pre None
* @post reset ALL global variables
* @param None
* @return None
*/
"""
func reset() -> void:
	#reset all global variables back to original values
	in_anim = 0
	minigame = 0
	players_in_minigame = 0
	progress = 0
	_boss_tp_counter = 0
	_first_time_in_boss = false
	_player_died_final_boss = false
	_first_time_in_boss = false
	player_names = {}
	player_positions = {}
	player_input_vectors = {}
	current_matches = {}
	skeleton_damage= {"1":0,"2":0,"3":0,"4":0}
	player_health ={"1":0,"2":0,"3":0,"4":0}
	chandelier_damage = {"1":0,"2":0,"3":0,"4":0}
	bod_damage = {"1":0,"2":0,"3":0,"4":0}
	#reset other global variable loader files
	GameLoot.reset()
