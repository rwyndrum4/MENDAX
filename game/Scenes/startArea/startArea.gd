extends Control


# Member Variables:
var in_cave = false
var in_menu = false
onready var instructions: Label = $enterDirections
onready var settingsMenu = $SettingsMenu


"""
/*
* @pre Called when the node enters the scene tree for the first time
* @post runs all statements to initialize the scene (once)
* @param None
* @return None
*/
"""
func _ready():
	pass # Replace with function body.

"""
/*
* @pre Called for every frame
* @post changes scenes if player presses enter and is in the zone
* @param _delta -> time variable that can be optionally used
* @return None
*/
"""
func _process(_delta): #change to delta if using it
	check_settings()
	if in_cave:
		if Input.is_action_just_pressed("ui_accept",false):
			# warning-ignore:return_value_discarded
			get_tree().change_scene("res://Scenes/startArea/EntrySpace.tscn")

"""
/*
* @pre Called when player enters the Ares2D zone
* @post shows instructions on screen and sets in_cave to true
* @param _body -> body of the player
* @return None
*/
"""
func _on_Area2D_body_entered(_body: PhysicsBody2D): #change to body if want to use
	instructions.show()
	in_cave = true

"""
/*
* @pre Called when player exits the Ares2D zone
* @post hides instructions on screen and sets in_cave to false
* @param _body -> body of the player
* @return None
*/
"""
func _on_Area2D_body_exited(_body: PhysicsBody2D): #change to body if want to use
	in_cave = false
	instructions.hide()

"""
/*
* @pre Called for every frame inside process function
* @post Opens and closes settings when escape is pressed
* @param None
* @return None
*/
"""
func check_settings():
	if Input.is_action_just_pressed("ui_cancel",false) and not in_menu:
		settingsMenu.popup_centered()
		in_menu = true
	elif Input.is_action_just_pressed("ui_cancel",false) and in_menu:
		settingsMenu.hide()
		in_menu = false
