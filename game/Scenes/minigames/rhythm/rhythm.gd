"""
* Programmer Name - Ben Moeller
* Also partially inspired by https://github.com/LegionGames/Conductor-Example/blob/master/Scripts/Game.gd
* Description - File for controlling what happens in the rythtm game
* Date Created - 12/20/2022
* Date Revisions: 12/21/2022 - Adding support for other files
"""

extends Node2D

# Member Variables
onready var scores_tab = $Scores
onready var conductor = $Conductor
onready var combo_count = $Combo/combo_count
onready var perfect_count = $Combo/perfect_count
onready var good_count = $Combo/good_count
onready var okay_count = $Combo/okay_count
onready var misses_count = $Combo/misses_count
onready var onlineHandler = $onlineHandler
onready var full_combo = $Frame/FULL_COMBO

## Global Variables ##

var game_started: bool = false

# Score variables
var _score_dict: Dictionary = {} #hold the dictionary of all the player's scores
var _current_combo = 0 #current combo that the player holds
var _max_combo = 0 #max combo player gets (for stats purposes)
var _perfect_counter = 0 #variable to count how many greats player gets
var _good_counter = 0 #variable to count how many goods player gets
var _okay_counter = 0 #variable to count how many okays player gets
var _missed_counter = 0 #variable to count how many notes missed
var _combo_multiplier = 1 #variable to track how much to multiply points by
var _never_missed = true

# Song variables
var _song_position_in_beats = 0 #Tracks where the song is in terms of beats

# Lane variables
var lane = 0 #Lane to spawn a note in
var rand = 0 #Random number global
var note = load("res://Scenes/minigames/rhythm/note.tscn") #Note class
var hold_note = load("res://Scenes/minigames/rhythm/hold_note.tscn") #Hold Note class
var note_instance #Global instance of node to be spawned into the game
const MAX_LANES = 4

# Note speed
const FAST = 1000

enum _note_types {
	NOTE = 1,
	HOLD = 2
}

# Beat variables
################################################################################
# The way it works is that for every four beats there is a measure. After this
# measure, the measure will reset and another four beats will play, continuing 
# on until the song ends
################################################################################
var _measure_one_beat = 1
var	_measure_two_beat = 1 
var	_measure_three_beat = 1
var	_measure_four_beat = 1

const beatmap_file = preload("res://Scenes/minigames/rhythm/beatmap.gd")
onready var _map = beatmap_file.new()

"""
/*
* @pre Called when the rhythm game starts
* @post initialized everything
* @param None
* @return None
*/
"""
func _ready():
	$ButtonHelper.add_constant_override("separation", 110)
	randomize()
	GlobalSignals.emit_signal("toggleHotbar", false)
	GlobalSignals.emit_signal("show_money_text", false)
	# warning-ignore:return_value_discarded
	conductor.connect("finished",self,"end_rhythm_game")
	# warning-ignore:return_value_discarded
	Global.connect("all_players_arrived", self, "_can_start_game")
	# warning-ignore:return_value_discarded
	ServerConnection.connect("minigame_can_start", self, "_can_start_game_other")
	# warning-ignore:return_value_discarded
	conductor.connect("measure", self, "_on_Conductor_measure")
	# warning-ignore:return_value_discarded
	conductor.connect("beat", self, "_on_Conductor_beat")
	var username = Save.game_data.username
	add_player_score(username)
	initialize_combo_scores()
	if ServerConnection.match_exists() and ServerConnection.get_server_status():
		onlineHandler.setup_players(username)
		ServerConnection.send_spawn_notif()
		if ServerConnection._player_num == 1:
			#in case p1 is last player to get to minigame
			if Global.get_minigame_players() == Global.get_num_players() - 1:
				ServerConnection.send_minigame_can_start()
				game_started = true
				start_rhythm_game()
		else:
			var wait_for_start: Timer = Timer.new()
			add_child(wait_for_start)
			wait_for_start.wait_time = Global.WAIT_FOR_PLAYERS_TIME
			wait_for_start.one_shot = true
			wait_for_start.start()
			# warning-ignore:return_value_discarded
			wait_for_start.connect("timeout",self, "_start_timer_expired", [wait_for_start])
	#else if single player game
	else:
		start_rhythm_game()

"""
/*
* @pre Called once start time expires (happens once)
* @post deletes timer and starts game if necessary
* @param timer -> Timer
* @return None
*/
"""
func _start_timer_expired(timer):
	timer.queue_free()
	if not game_started:
		game_started = true
		start_rhythm_game()

"""
/*
* @pre Called once all players have spawned into the minigame
* 	only run by PLAYER 1
* @post sends signal to other players to start, and start game
* @param None
* @return None
*/
"""
func _can_start_game():
	game_started = true
	ServerConnection.send_minigame_can_start()
	start_rhythm_game()

"""
/*
* @pre Called when non-player 1 player receives signal to start game
* @post starts the game if timer hasn't already done it for it
* @param None
* @return None
*/
"""
func _can_start_game_other():
	if not game_started:
		game_started = true
		start_rhythm_game()

"""
/*
* @pre Called once the rhythm game can be started
* @post Starts playing the song
* @param None
* @return None
*/
"""
func start_rhythm_game():
	Global.reset_minigame_players() #Reset minigame players and go to cave scene
	$Frame/wait_on_players.queue_free()
	var instructions:Popup = load("res://Scenes/minigames/rhythm/instructions.tscn").instance()
	$Frame.add_child(instructions)
	instructions.popup(Rect2(170,90,900,590))
	instructions.connect("done_explaining",self, "_delete_instr_and_start_song", [instructions])

"""
/*
* @pre None
* @post Deletes instructions and starts the game after 2 sec pause
* @param instr_scn -> Popup (popup scene to be deleted)
* @return None
*/
"""
func _delete_instr_and_start_song(instr_scn):
	instr_scn.queue_free()
	var wait_timer = Timer.new()
	add_child(wait_timer)
	wait_timer.wait_time = 2
	wait_timer.one_shot = true
	wait_timer.start()
	yield(wait_timer, "timeout")
	wait_timer.queue_free()
	conductor.play_with_beat_offset(0)
	var fade_buttons_tmr = Timer.new()
	fade_buttons_tmr.wait_time = 0.1
	fade_buttons_tmr.one_shot = false
	add_child(fade_buttons_tmr)
	fade_buttons_tmr.start()
	fade_buttons_tmr.connect("timeout",self, "_reduce_instr_mod", [fade_buttons_tmr])

"""
* @pre None
* @post Will gradually decrease the modulation of the helper buttons
* @param tmr (timer to stop after a a certain amount of time)
"""
func _reduce_instr_mod(tmr):
	if _song_position_in_beats < 10:
		$ButtonHelper.modulate.a8 -= 5
	else:
		tmr.disconnect("timeout", self, "_reduce_instr_mod")
		tmr.queue_free()
		$ButtonHelper.queue_free()

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
	var added_score = int(new_points * _combo_multiplier)
	if ServerConnection.match_exists() and ServerConnection.get_server_status():
		onlineHandler.send_score_to_server(added_score)
	if _score_dict.has(p_name):
		#get the current score as a string
		var label_txt = _score_dict.get(p_name).text
		var current_score = label_txt.get_slice(" ",1)
		var cleaned_data = label_txt.replace(current_score,"")
		_score_dict.get(p_name).text = cleaned_data + str(int(current_score) + added_score)
	check_placement() #check if scores need to be reordered

#Same as above but adapted for when a score comes from another player
func change_score_from_server(p_name:String, new_points:int):
	if _score_dict.has(p_name):
		#get the current score as a string
		var label_txt = _score_dict.get(p_name).text
		var current_score = label_txt.get_slice(" ",1)
		var cleaned_data = label_txt.replace(current_score,"")
		_score_dict.get(p_name).text = cleaned_data + str(int(current_score) + int(new_points))
	check_placement() #check if scores need to be reordered

#Custom sort function for check_placement
class myCustomSorter:
	static func sort_asc(a,b):
		if a[1] > b[1]:
			return true
		return false
"""
/*
* @pre None
* @post order the players based on who has the best score
* @param None
* @return None
*/
"""
func check_placement():
	var ordered_places: Array = []
	for p_name in _score_dict.keys():
		ordered_places.append([p_name, int(_score_dict[p_name].text)])
	ordered_places.sort_custom(myCustomSorter, "sort_asc")
	var inc = 1
	for obj in ordered_places:
		$Scores.move_child(_score_dict[obj[0]], inc)
		inc += 1

func get_sorted_results() -> Array:
	var ordered_places: Array = []
	for p_name in _score_dict.keys():
		ordered_places.append([p_name, int(_score_dict[p_name].text)])
	ordered_places.sort_custom(myCustomSorter, "sort_asc")
	return ordered_places
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
			_never_missed = false
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
		1: if _measure_one_beat > 0:
			_spawn_note_fixed_note(_song_position_in_beats)
		2: if _measure_two_beat > 0:
			_spawn_note_fixed_note(_song_position_in_beats)
		3: if _measure_three_beat > 0:
			_spawn_note_fixed_note(_song_position_in_beats)
		4: if _measure_four_beat > 0:
			_spawn_note_fixed_note(_song_position_in_beats)

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
	#If done with song, print song complete/full combo
	if _song_position_in_beats == 410 and _never_missed:
		full_combo.start_ani(true)
	elif _song_position_in_beats == 410 and (not _never_missed):
		full_combo.start_ani(false)

"""
/*
* @pre Called when the song has ended
* @post Show final winner screen, then leave minigame
* @param None
* @return None
*/
"""
func end_rhythm_game():
	#Final results sorted
	var results = get_sorted_results()
	#Giving players money based on results
	var ctr = 1
	#Giving players coins dependent on their placement
	for arr in results:
		var n = Global.get_player_num(arr[0])
		var score = (5 - ctr) * 5
		GameLoot.add_to_coin(n,score)
		ctr += 1
	#Load ending scene with results
	var end_screen:Popup = load("res://Scenes/minigames/rhythm/endScreen.tscn").instance()
	$Frame.add_child(end_screen)
	end_screen.add_results(results)
	end_screen.popup_centered()
	full_combo.hide()
	#Timer to look at results
	var leaderbrd_tmr = Timer.new()
	add_child(leaderbrd_tmr)
	leaderbrd_tmr.wait_time = 6
	leaderbrd_tmr.one_shot = true
	leaderbrd_tmr.start()
	yield(leaderbrd_tmr, "timeout")
	leaderbrd_tmr.queue_free()
	#Perform final steps before going back to cave
	GlobalSignals.emit_signal("toggleHotbar", true)
	GlobalSignals.emit_signal("show_money_text", true)
	if ServerConnection.match_exists() and ServerConnection.get_server_status():
		ServerConnection.send_num_good_notes(_good_counter)
		Global._rhythm_goods_hit(ServerConnection._player_num, _good_counter)
	Global.state = Global.scenes.CAVE

"""
/*
* @pre Called for each beat that is called with a note
* @post Helps spawn in the notes to the game, with you specifying which lane
* @param lane_num -> int (lane to spawn note in),
* 		 note_type -> int (type of note to be spawned),
* 		 height -> int (height of hold_note, 0 if not specified)
* @return None
*/
"""
func _spawn_note_fixed_note(beat_pos:int):
	var data:Array = []
	if len(_map.beatmap) + 1 < beat_pos:
		data = [0]
	else:
		data = _map.beatmap[beat_pos]
	var num_notes = data[0]
	if num_notes == 0:
		return
	var lanes = data[1]
	var types_of_notes = data[2]
	var heights = data[3]
	for i in range(num_notes):
		var local_note
		var note_type = types_of_notes[i]
		match note_type:
			_note_types.NOTE: local_note = note
			_note_types.HOLD: local_note = hold_note
		note_instance = local_note.instance()
		if note_type == _note_types.HOLD:
			note_instance.set_height(heights[i])
		note_instance.initialize(lanes[i], FAST)
		add_child(note_instance)

#Function to generate random note, not used anymore
func gen_rand_note() -> Object:
	if (randi() % 100) > 25:
		return note
	else:
		return hold_note

#Function to spawn random notes, not used anymore
func _spawn_notes_random(to_spawn: int):
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
