#Inspired by https://github.com/LegionGames/Conductor-Example/blob/master/Scripts/ArrowButton.gd

extends AnimatedSprite

export var _color_animation: String = ""

var _perfect = false #tracks if a perfect is possible
var _good = false #tracks if a good is possible
var _okay = false #tracks if an okay is possible
var _current_note = null #tracks if a note is currently in scope

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
		if event.is_action_pressed(_color_animation, false):
			if _current_note != null:
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
				reset()
			else:
				#player missed
				get_parent().increment_counters(0)

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
		_good = true

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
		_okay = true
		_current_note = area

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
		_okay = false
		_current_note = null

"""
/*
* @pre Called inside of input function
* @post resets all current parameters
* @param area -> Area2D
* @return None
*/
"""
func reset():
	_current_note = null
	_perfect = false
	_good = false
	_okay = false
