"""
* Programmer Name - Ben Moeller, Freeman Spray, Jason Truong, Mohit Garg, Will Wyndrum
* Description - File for controlling the what happens with actions within the main menu
* Date Created - 9/16/2022
* Date Revisions:
	9/17/2022 - Added options menu functionality
	9/18/2022 - Added join code functionality
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
* @knownFaults pop-up size and location depends not only on whether the screen is windowed or fullscreen,
*   but also whether the market has been entered in the current iteration of the game
* @knownFaults animated fire does not anchor to its position when the screen is adjusted
*/
"""
func _on_Options_pressed():
	settingsMenu.popup_centered()

"""
/*
* @pre Market Button is pressed
* @post Scene change to store scene
* @param None
* @return None
* @knownFaults resets join code to default (XXXX)
*/
"""
#When button pressed switches to Store scene
func _on_Market_pressed():
	SceneTrans.change_scene("res://StoreElements/StoreVars.tscn")

"""
/*
* @pre Tests Button is pressed
* @post not yet implemented
* @param None
* @return None
*/
"""
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

"""
/*
* @pre "Get Code" Button is pressed
* @post Generate and display string of four random letters in the "code" RichTextLabel
* @param None
* @return None
*/
"""
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
	
"""
/*
* @pre Helper function to _on_GetCode_button_up(). Only called within the context of the function
* @post Generate a random number between 1 and 26 (inclusive)
* @param rng, a RandomNumberGenerator class object
* @return randomAlphabetIndex, the random number generated using rng.
*/
"""
func getRandAlphInd(rng):
		rng.randomize()
		var randomAlphabetIndex = rng.randi_range(0, 25)
		return randomAlphabetIndex
