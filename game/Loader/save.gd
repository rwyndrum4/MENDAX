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
#fields that someones save file should have
const DEFAULT: Dictionary = {
	"username" : "",
	"fullscreen_on": false,
	"vsync_on": false,
	"display_fps": false,
	"max_fps": 60,
	"bloom_on": false,
	"brightness": 1,
	"master_vol": -10,
	"music_vol": -10,
	"sfx_vol": -10,
	"mouse_sens": 0.1,
	"money": 0
}

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
		game_data = DEFAULT
		save_data()
	file.open(SAVEFILE, File.READ)
	game_data = file.get_var()
	file.close()
	#If the users current save file does not have all the right fields
	if not check_file():
		fix_data()
		save_data()

"""
* @pre called when loading in save data
* @post checks to make sure all fields are present
* @return None
"""
func check_file() -> bool:
	return game_data.keys() == DEFAULT.keys()

"""
* @pre called when save file has missing fields
* @post adds needed fields to current save file
* @return None
"""
func fix_data() -> void:
	for f in DEFAULT.keys():
		if not game_data.has(f):
			game_data[f] = DEFAULT.get(f)

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
