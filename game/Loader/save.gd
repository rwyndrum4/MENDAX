#based on tutorial provided by https://www.youtube.com/watch?v=cQkEPej_gRU

extends Node

#filename of the user's save file
const SAVEFILE = "user://saveFile.save"

#dictionary to store the user data
var game_data = {}

#function that is called when the game is turned on
#loads user's already defined data OR created new data
func _ready():
	load_data()
	
#loads the data currently in user's save file, or
#creates a new one if first time playing and sets
#default values
func load_data():
	var file = File.new()
	if not file.file_exists(SAVEFILE):
		game_data = {
			"fullscreen_on": false,
			"vsync_on": false,
			"display_fps": false,
			"max_fps": 0,
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
		
#saves data currently in game_data object to file
func save_data():
	var file = File.new()
	file.open(SAVEFILE, File.WRITE)
	file.store_var(game_data)
	file.close()
