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
var player_inventory = preload("res://Inventory/Inventory.tscn").instance()
var hotbar = preload("res://Inventory/Hotbar.tscn").instance()

#Entry First Time
var in_anim: int = 0

#track minigame
var minigame: int = 0
var players_in_minigame: int = 0

# Counter tracking progression in final boss fight
var progress = 0

# Signals
signal all_players_arrived()

"""
-----------------------------SCENE LOADER INSTRUCTION-------------------------------------
- state -> this is the variable that tracks what scene the game is currently in
- You set state to one of the enum states defined in scene
- For example, if you want to change scene to main menu:
  Global.state = Global.scene.MAIN_MENU
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
	RHYTHM_MINIGAME,
	GAMEOVER,
	QUIZ,
	DILEMMA,
	END_SCREEN
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
* @return None
*/
"""
func get_player_name(player_num: int) -> String:
	return player_names[str(player_num)]

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
