"""
* Programmer Name - Jason Truong, Benjamin Moeller
* Description - File for global variables such as health, money, and etc.
* Date Created - 9/16/2022
* Date Revisions:
	- 10/22/2022: Added functionality for tracking scene changes
"""
extends Node

# Player's balance
var money = 0
var player_inventory = preload("res://Inventory/Inventory.tscn").instance();

#Entry First Time
var entry = 0
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
enum scenes {
	MAIN_MENU,
	OPTIONS_FROM_MAIN,
	MARKET,
	START_AREA,
	CAVE,
	RIDDLER_MINIGAME
	ARENA_MINIGAME
}

# Current players in scnene
var current_players:Dictionary = {}
# Hold array of player positions
var player_positions:Dictionary = {}
# Hold current matches
var current_matches: Dictionary = {}

func _ready():
	# warning-ignore:return_value_discarded
	ServerConnection.connect("state_updated",self,"_player_positions_updated")

func get_player_pos(player_id:int):
	return player_positions[str(player_id)]

func _player_positions_updated(id, position):
	print("x:",position.x)
	print("y:",position.y)
	player_positions[str(id)] = position
