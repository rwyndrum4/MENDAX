"""
* Programmer Name - Ben Moeller
* Also partially inspired by https://github.com/LegionGames/Conductor-Example/blob/master/Scripts/Game.gd
* Description - File for controlling what happens in the rythtm game
* Date Created - 12/20/2022
* Date Revisions: 12/21/2022 - Adding support for other files
"""

## TODO ##
################################################
# Map notes to song
# Handle notes being spawned on top of eachother
# Online functionality
# Sabatoge mechanic
# Beginning and end screen
# Handle multiple players joining
# Multiple Difficulties?
################################################

extends Node2D

# Member Variables
onready var scores_tab = $Scores
onready var conductor = $Conductor
onready var combo_count = $Combo/combo_count
onready var perfect_count = $Combo/perfect_count
onready var good_count = $Combo/good_count
onready var okay_count = $Combo/okay_count
onready var misses_count = $Combo/misses_count

## Global Variables ##

# Score variables
var _score_dict: Dictionary = {} #hold the dictionary of all the player's scores
var _current_combo = 0 #current combo that the player holds
var _max_combo = 0 #max combo player gets (for stats purposes)
var _perfect_counter = 0 #variable to count how many greats player gets
var _good_counter = 0 #variable to count how many goods player gets
var _okay_counter = 0 #variable to count how many okays player gets
var _missed_counter = 0 #variable to count how many notes missed
var _combo_multiplier = 1 #variable to track how much to multiply points by

# Song variables
var _song_position_in_beats = 0 #Tracks where the song is in terms of beats

# Lane variables
var lane = 0 #Lane to spawn a note in
var rand = 0 #Random number global
var note = load("res://Scenes/minigames/rhythm/note.tscn") #Note class
var hold_note = load("res://Scenes/minigames/rhythm/hold_note.tscn") #Hold Note class
var note_instance #Global instance of node to be spawned into the game
const MAX_LANES = 4

# Note speeds
const SLOW = 500
const MEDIUM = 750
const FAST = 1000
const GODLIKE = 1500

# Beat variables
################################################################################
# The way it works is that for every four beats there is a measure. After this
# measure, the measure will reset and another four beats will play, continuing 
# on until the song ends
################################################################################
var _measure_one_beat = 1 #First beat
var _measure_two_beat = 0 #Second beat
var _measure_three_beat = 0 #Third beat
var _measure_four_beat = 1 #Fourth beat

"""
/*
* @pre Called when the rhythm game starts
* @post initialized everything
* @param None
* @return None
*/
"""
func _ready():
	randomize()
	conductor.connect("measure", self, "_on_Conductor_measure")
	conductor.connect("beat", self, "_on_Conductor_beat")
	conductor.play_with_beat_offset(8)
	add_player_score(Save.game_data.username)
	initialize_combo_scores()

"""
/*
* @pre Called in ready function
* @post initializes the combo text on the right hand side
* @param None
* @return None
*/
"""
func initialize_combo_scores():
	combo_count.text = "Combo: 0"
	perfect_count.text = "Perfect: 0"
	good_count.text = "Good: 0"
	okay_count.text = "Okay: 0"
	misses_count.text = "Misses: 0"

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
	var added_score = new_points * _combo_multiplier
	if _score_dict.has(p_name):
		#get the current score as a string
		var label_txt = _score_dict.get(p_name).text
		var current_score = label_txt.get_slice(" ",1)
		var cleaned_data = label_txt.replace(current_score,"")
		_score_dict.get(p_name).text = cleaned_data + str(int(current_score) + added_score)

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
		0: 
			_current_combo = 0
			_combo_multiplier = 1
		_: 
			_current_combo += 1
			_combo_multiplier += 0.05
			if _current_combo > _max_combo:
				_max_combo = _current_combo
	#Update combo counter label text
	combo_count.text = "Combo: " + str(_current_combo)
	
	#Increment the correct type of hit/miss
	match type:
		0: 
			_missed_counter += 1
			misses_count.text = "Misses: " + str(_missed_counter)
		1: 
			_okay_counter += 1
			okay_count.text = "Okay: " + str(_okay_counter)
		2: 
			_good_counter += 1
			good_count.text = "Good: " + str(_good_counter)
		3: 
			_perfect_counter += 1
			perfect_count.text = "Perfect: " + str(_perfect_counter)

"""
/*
* @pre Called when Conductor class sends a measure signal
* @post TODO
* @param measure_position -> Number
* @return None
*/
"""
func _on_Conductor_measure(measure_position):
	match measure_position:
		1: _spawn_notes(_measure_one_beat)
		2: _spawn_notes(_measure_two_beat)
		3: _spawn_notes(_measure_three_beat)
		4: _spawn_notes(_measure_four_beat)

"""
/*
* @pre Called when Conductor class sends a beat signal
* @post Helps say how the song should play out according to the beat position
* @param beat_position -> Number
* @return None
*/
"""
func _on_Conductor_beat(beat_position):
	_song_position_in_beats = beat_position
	if _song_position_in_beats > 0:
		_measure_one_beat = 1 
		_measure_two_beat = 1 
		_measure_three_beat = 1
		_measure_four_beat = 1
	if _song_position_in_beats > 36:
		_measure_one_beat = 1 
		_measure_two_beat = 1 
		_measure_three_beat = 1 
		_measure_four_beat = 1 
	if _song_position_in_beats > 98:
		_measure_one_beat = 2
		_measure_two_beat = 0 
		_measure_three_beat = 1 
		_measure_four_beat = 0 
	if _song_position_in_beats > 132:
		_measure_one_beat = 0
		_measure_two_beat = 2
		_measure_three_beat = 0
		_measure_four_beat = 2
	if _song_position_in_beats > 162:
		_measure_one_beat = 2 
		_measure_two_beat = 2 
		_measure_three_beat = 1 
		_measure_four_beat = 1 
	if _song_position_in_beats > 194:
		_measure_one_beat = 2
		_measure_two_beat = 2 
		_measure_three_beat = 1 
		_measure_four_beat = 2 
	if _song_position_in_beats > 228:
		_measure_one_beat = 0 
		_measure_two_beat = 2 
		_measure_three_beat = 1 
		_measure_four_beat = 2 
	if _song_position_in_beats > 258:
		_measure_one_beat = 1 
		_measure_two_beat = 2 
		_measure_three_beat = 1 
		_measure_four_beat = 2
	if _song_position_in_beats > 288:
		_measure_one_beat = 0 
		_measure_two_beat = 2 
		_measure_three_beat = 0
		_measure_four_beat = 2
	if _song_position_in_beats > 322:
		_measure_one_beat = 3
		_measure_two_beat = 2 
		_measure_three_beat = 2 
		_measure_four_beat = 1 
	if _song_position_in_beats > 388:
		_measure_one_beat = 1 
		_measure_two_beat = 0 
		_measure_three_beat = 0 
		_measure_four_beat = 0 
	if _song_position_in_beats > 396:
		_measure_one_beat = 0 
		_measure_two_beat = 0 
		_measure_three_beat = 0 
		_measure_four_beat = 0 

"""
/*
* @pre Called for each beat that is called with a note
* @post Helps spawn in the notes to the game
* @param to_spawn -> int (number of notes to spawn)
* @return None
*/
"""
func _spawn_notes(to_spawn: int):
	var local_note = gen_rand_note()
	if to_spawn > 0:
		lane = randi() % MAX_LANES
		note_instance = local_note.instance()
		note_instance.initialize(lane, FAST)
		add_child(note_instance)
	if to_spawn > 1:
		for _i in range(0, to_spawn):
			while rand == lane:
				rand = randi() % MAX_LANES
			lane = rand
			note_instance = local_note.instance()
			note_instance.initialize(lane, FAST)
			add_child(note_instance)

"""
/*
* @pre None
* @post Picks whether a normal or hold not is spawned
* 75% chance for a normal note, 25% for a hold
* @param None
* @return Note Object
*/
"""
func gen_rand_note() -> Object:
	if (randi() % 100) > 25:
		return note
	else:
		return hold_note
