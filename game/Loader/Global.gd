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

#Entry First Time
var entry = 0
var in_anim = 0

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
	MARKET,
	START_AREA,
	CAVE,
	RIDDLER_MINIGAME
}

# Current players in scnene
var current_players:Dictionary = {}
# Hold array of player positions
var player_positions:Array = []

func get_player_pos(player_id:String):
	for player in player_positions:
		if player['id'] == player_id:
			return player['pos']
