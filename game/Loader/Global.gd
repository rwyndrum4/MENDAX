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
var money = 0
var player_inventory = preload("res://Inventory/Inventory.tscn").instance()

#Entry First Time
var in_anim = 0

#track minigame
var minigame = 0

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
	START_AREA,
	CAVE,
	RIDDLER_MINIGAME,
	ARENA_MINIGAME
}

# Hold dictionary of player positions
var player_positions:Dictionary = {}
# Hold dictionary of player input vectors
var player_input_vectors:Dictionary = {}
# Hold current matches, for joining matches
var current_matches: Dictionary = {}

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

"""
/*
* @pre None
* @post adds a match to the current_matches variable
* @param lobby_name -> String, match_id -> String
* @return None
*/
"""
func add_match(lobby_name:String,match_id:String):
	#adds to dictionary
	current_matches[lobby_name] = match_id

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
	return current_matches[lobby_name]

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
