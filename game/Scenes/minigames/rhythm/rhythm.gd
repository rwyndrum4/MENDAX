"""
* Programmer Name - Ben Moeller
* Description - File for controlling what happens in the rythtm game
* Date Created - 12/20/2022
* Date Revisions:
"""

extends Node2D

# Member Variables
onready var scores_tab = $Scores
onready var conductor = $Conductor

# Global Variables
var score_dict: Dictionary = {} #hold the dictionary of all the player's scores
var max_combo = 0 #current combo that the player holds
var perfect_counter = 0 #variable to count how many greats player gets
var good_counter = 0 #variable to count how many goods player gets
var okay_counter = 0 #variable to count how many okays player gets
var missed_counter = 0 #variable to count how many notes missed

"""
/*
* @pre Called when the rhythm game starts
* @post initialized everything
* @param None
* @return None
*/
"""
func _ready():
	conductor.connect("measure", "_on_Conductor_measure")
	conductor.connect("beat", "_on_Conductor_beat")
	randomize()
	conductor.play_with_beat_offset(8)
	add_player_score(Save.game_data.username)

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
	score_dict[p_name] = score_label
	scores_tab.add_child(score_label)

func change_score(p_name: String, new_score: int):
	if p_name in score_dict:
		#get the current score as a string
		var label_txt = score_dict.get(p_name).text
		var current_score = label_txt.get_slice(" ",1)
		var cleaned_data = label_txt.replace(current_score,"")
		score_dict.get(p_name).text = cleaned_data + str(new_score)

func _on_Conductor_measure(position):
	pass

func _on_Conductor_beat(position):
	pass

func reset_combo():
	max_combo = 0
