"""
* Programmer Name - Ben Moeller, Freeman Spray, Jason Truong, Mohit Garg, Will Wyndrum
* Description - File for controlling the what happens with actions within the main menu
* Date Created - 9/16/2022
* Date Revisions:
	9/17/2022 - Added options menu functionality
	9/21/2022 - Fixing issue with fps label not working correctly
"""

extends Control


# Declare member variables here. Examples:
onready var settingsMenu = $SettingsMenu
onready var fpsLabel = $fpsLabel


"""
/*
* @pre called when main menu is loaded in (run once)
* @post runs preliminary code to help user functionality
* @param None
* @return None
*/
"""
func _ready():
	$VBoxContainer/Start.grab_focus()
	fpsLabel._on_fps_displayed(Save.game_data.display_fps)


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass

"""
/*
* @pre Start Button is pressed
* @post Scene change to start of game
* @param None
* @return None
*/
"""
func _on_Start_pressed():
	pass # Replace with function body.

"""
/*
* @pre Options Button is pressed
* @post Scene change to options menu
* @param None
* @return None
*/
"""
func _on_Options_pressed():
	settingsMenu.popup_centered()

"""
/*
* @pre Button is pressed
* @post Scene change to store scene
* @param None
* @return None
*/
"""
#When button pressed switches to Store scene
func _on_Market_pressed():
	SceneTrans.change_scene("res://StoreElements/StoreVars.tscn")


func _on_Tests_pressed():
	pass # Replace with function body.

"""
/*
* @pre Quit Button is pressed
* @post Application is closed
* @param None
* @return None
*/
"""
func _on_Quit_pressed():
	get_tree().quit()


func _on_GetCode_button_up():
	var letters = ['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 
				   'J', 'K', 'L', 'M', 'N', 'O', 'P', 'Q', 'R', 
				   'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z',]
	var rng = RandomNumberGenerator.new()
	var index1 = getRandAlphInd(rng)
	var index2 = getRandAlphInd(rng)
	var index3 = getRandAlphInd(rng)
	var index4 = getRandAlphInd(rng)
	var code = letters[index1] + letters[index2] + letters[index3] + letters[index4]
	$joinCodeContainer/code.set("text", code)
	
func getRandAlphInd(rng):
		rng.randomize()
		var randomAlphabetIndex = rng.randi_range(0, 25)
		return randomAlphabetIndex
