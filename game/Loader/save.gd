"""
* Programmer Name - Ben Moeller
* Description - File for controlling saving user settings to file on their computer
* Date Created - 9/17/2022
* Date Revisions:
	9/18/2022 - Fixing issue with load_data function (indent was off)
* Citations:
	Based on tutorial from https://www.youtube.com/watch?v=cQkEPej_gRU
"""

extends Node

#filename of the user's save file
const SAVEFILE = "user://saveFile.save"

#dictionary to store the user data
var game_data = {}

"""
/*
* @pre called when game is loaded (runs once)
* @post reads user data or creates new data if first time playing
* @param None
* @return None
*/
"""
func _ready():
	load_data()

"""
/*
* @pre called by _ready function
* @post loads user's current data or creates new data if first time playing
* @param None
* @return None
*/
"""
func load_data():
	var file = File.new()
	if not file.file_exists(SAVEFILE):
		game_data = {
			"username" : "CHANGE-USERNAME-IN-SETTINGS",
			"fullscreen_on": false,
			"vsync_on": false,
			"display_fps": false,
			"max_fps": 0,
			"bloom_on": false,
			"brightness": 1,
			"master_vol": -10,
			"music_vol": -10,
			"sfx_vol": -10,
			"mouse_sens": 0.1,
		}
		save_data()
	file.open(SAVEFILE, File.READ)
	game_data = file.get_var()
	file.close()

"""
/*
* @pre called by functions that want to save data from game_data to file
* @post saves data currently in game_data object to file
* @param None
* @return None
*/
"""
func save_data():
	var file = File.new()
	file.open(SAVEFILE, File.WRITE)
	file.store_var(game_data)
	file.close()
