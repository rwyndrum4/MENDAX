"""
* Programmer Name - Ben Moeller
* Description - File for controlling what happens in the rythtm game
* Date Created - 12/20/2022
* Date Revisions: 12/21/2022 - Adding support for other files
"""

extends Node2D

# Member Variables
onready var scores_tab = $Scores
onready var conductor = $Conductor

# Global Variables
var _score_dict: Dictionary = {} #hold the dictionary of all the player's scores
var _max_combo = 0 #current combo that the player holds
var _perfect_counter = 0 #variable to count how many greats player gets
var _good_counter = 0 #variable to count how many goods player gets
var _okay_counter = 0 #variable to count how many okays player gets
var _missed_counter = 0 #variable to count how many notes missed

var NOTE = load("res://Scenes/minigames/rhythm/note.tscn")

"""
/*
* @pre Called when the rhythm game starts
* @post initialized everything
* @param None
* @return None
*/
"""
func _ready():
	conductor.connect("measure", self, "_on_Conductor_measure")
	conductor.connect("beat", self, "_on_Conductor_beat")
	randomize()
	conductor.play_with_beat_offset(8)
	add_player_score(Save.game_data.username)

"""
/*
* @pre None
* @post Adds players initial score to the side score holder
* @param p_name -> String (name of player)
* @return None
*/
"""
func add_player_score(p_name: String):
	var silver_font = DynamicFont.new()
	silver_font.font_data = load("res://Assets/Silver.ttf")
	silver_font.size = 40
	silver_font.outline_size = 4
	silver_font.outline_color = Color(0,0,0,1)
	silver_font.use_filter = true
	var score_label: Label = Label.new()
	score_label.text = p_name + ": 0000"
	score_label.add_font_override("font",silver_font)
	score_label.add_color_override("font_color",Color.white)
	_score_dict[p_name] = score_label
	scores_tab.add_child(score_label)

"""
/*
* @pre None
* @post changes the player score inside of the left hand side score holder
* @param p_name -> String (player name), new_score -> Int (New score to put in score holder)
* @return None
*/
"""
func change_score(p_name: String, new_points: int):
	if _score_dict.has(p_name):
		#get the current score as a string
		var label_txt = _score_dict.get(p_name).text
		var current_score = label_txt.get_slice(" ",1)
		var cleaned_data = label_txt.replace(current_score,"")
		_score_dict.get(p_name).text = cleaned_data + str(int(current_score) + new_points)

"""
/*
* @pre Called when Conductor class sends a measure signal
* @post TODO
* @param measure_position -> Number
* @return None
*/
"""
func _on_Conductor_measure(measure_position):
	pass

"""
/*
* @pre Called when Conductor class sends a beat signal
* @post TODO
* @param beat_position -> Number
* @return None
*/
"""
func _on_Conductor_beat(beat_position):
	pass

"""
/*
* @pre None
* @post Increments or resets the combo counter, plus type counters
* @param type -> Int (Type of not hit, aka perfect, good, okay, etc)
* @return None
*/
"""
func increment_counters(type: int):
	#Increment combo if player hits, else reset combo
	match type:
		0: _max_combo = 0
		_: _max_combo += 1
	
	#Increment the correct type of hit/miss
	match type:
		0: _missed_counter += 1
		1: _okay_counter += 1
		2: _good_counter += 1
		3: _perfect_counter += 1

"""
/*
* @pre None
* @post resets the combo to zero
* @param None
* @return None
*/
"""
func reset_combo():
	_max_combo = 0
