#Inspired by https://github.com/LegionGames/Conductor-Example/blob/master/Scripts/ArrowButton.gd

extends AnimatedSprite

export var _color_animation: String = ""

var _perfect = false #tracks if a perfect is possible
var _good = false #tracks if a good is possible
var _okay = false #tracks if an okay is possible
var _current_note = null #tracks if a note is currently in scope
var _save_node = null #note to act upon
var _note_type = "" #keep track of what a note was

#Variables to help track if it is a hold note, what has been hit
var first_hit = false

"""
/*
* @pre Called when the rhythm game starts
* @post initialized everything
* @param None
* @return None
*/
"""
func _ready():
	match _color_animation.to_lower():
		"blue_rhythm": animation = "blue"
		"green_rhythm": animation = "green"
		"orange_rhythm": animation = "orange"
		"red_rhythm": animation = "red"
		_: printerr("Invalid color for hit_button")

"""
/*
* @pre Called when a button is pressed
* @post checks to see if player hit at a good time or not
* @param event -> InputEvent
* @return None
*/
"""
func _unhandled_input(event):
	if event.is_action(_color_animation):
		#When key is pressed down (for both note and hold_note)
		if event.is_action_pressed(_color_animation, false):
			if is_instance_valid(_current_note):
				if _perfect:
					play()
					get_parent().increment_counters(3)
					_current_note.destroy(3)
				elif _good:
					play()
					get_parent().increment_counters(2)
					_current_note.destroy(2)
				elif _okay:
					play()
					get_parent().increment_counters(1)
					_current_note.destroy(1)
				if _note_type == "note":
					reset()
				elif _note_type == "hold_note":
					_current_note.brighten_hold_zone()
					reset_no_null()
		#When a key is released (ONLY FOR HOLD_NOTE)
		elif event.is_action_released(_color_animation, false) and _note_type == "hold_note":
			if is_instance_valid(_current_note):
				if _perfect:
					play()
					get_parent().increment_counters(3)
					_current_note.destroy(3)
				elif _good:
					play()
					get_parent().increment_counters(2)
					_current_note.destroy(2)
				elif _okay:
					play()
					get_parent().increment_counters(1)
					_current_note.destroy(1)
			else:
				get_parent().increment_counters(0)
				if is_instance_valid(_save_node):
					_save_node.reset_hold_zone()

"""
/*
* @pre Called when perfect area is entered
* @post sets _perfect to true
* @param area -> Area2D
* @return None
*/
"""
func _on_perfect_area_area_entered(area):
	if area.is_in_group("note"):
		_perfect = true

"""
/*
* @pre Called perfect area is exited
* @post sets _perfect to false
* @param area -> Area2D
* @return None
*/
"""
func _on_perfect_area_area_exited(area):
	if area.is_in_group("note"):
		_perfect = false

"""
/*
* @pre Called when good area is entered
* @post sets _good to true
* @param area -> Area2D
* @return None
*/
"""
func _on_good_area_area_entered(area):
	if area.is_in_group("note"):
		_good = true

"""
/*
* @pre Called when good area is exited
* @post sets _good to false
* @param area -> Area2D
* @return None
*/
"""
func _on_good_area_area_exited(area):
	if area.is_in_group("note"):
		_good = false

"""
/*
* @pre Called when okay area is entered
* @post sets _okay to true and sets current note to area given
* @param area -> Area2D
* @return None
*/
"""
func _on_okay_area_area_entered(area):
	if area.is_in_group("note"):
		_current_note = area
		_save_node = area
		_note_type = _current_note.get_type()
		_okay = true

"""
/*
* @pre Called when okay area is exited
* @post sets _okay to false and sets current note to null since it is gone now
* @param area -> Area2D
* @return None
*/
"""
func _on_okay_area_area_exited(area):
	if area.is_in_group("note"):
		_current_note = null
		_okay = false

"""
/*
* @pre Called inside of input function
* @post resets all current parameters
* @param None
* @return None
*/
"""
func reset():
	_current_note = null
	_perfect = false
	_good = false
	_okay = false
	frame = 0

"""
/*
* @pre Called inside of input function
* @post resets all current parameters, but only for hold_notes
* @param None
* @return None
*/
"""
func reset_no_null():
	_perfect = false
	_good = false
	_okay = false
	frame = 0
