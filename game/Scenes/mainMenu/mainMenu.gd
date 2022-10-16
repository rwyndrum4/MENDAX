"""
* Programmer Name - Ben Moeller, Freeman Spray, Jason Truong, Mohit Garg, Will Wyndrum
* Description - File for controlling the what happens with actions within the main menu
* Date Created - 9/16/2022
* Date Revisions:
	9/17/2022 - Added options menu functionality
	9/18/2022 - Added join code functionality
	9/21/2022 - Fixing issue with fps label not working correctly
	10/1/2022 - Added the ability to move with keyboard in settings menu
	10/1/2022 - Fixed options menu movment
"""

extends Control

# Member Variables
onready var startButton = $VBoxContainer/Start
onready var settingsMenu = $SettingsMenu
onready var fpsLabel = $fpsLabel
onready var worldEnv = $WorldEnvironment
onready var usernameAsk = $askForUsername
onready var usernameInput = $askForUsername/LineEdit


"""
/*
* @pre called when main menu is loaded in (run once)
* @post runs preliminary code to help user functionality
* @param None
* @return None
*/
"""
func _ready():
	#Grab focus on start button so keys can be used to navigate buttons
	startButton.grab_focus()
	#Call function to use user saved fps
	fpsLabel._on_fps_displayed(Save.game_data.display_fps)
	#Call functions to use user saved brightness and bloom values
	worldEnv._on_brightness_toggled(Save.game_data.brightness)
	worldEnv._on_bloom_toggled(Save.game_data.bloom_on)
	#Call functions to sync audio settings with user save
	settingsMenu._on_MasterVolSlider_value_changed(Save.game_data.master_vol)
	settingsMenu._on_MusicVolSlider_value_changed(Save.game_data.music_vol)
	settingsMenu._on_SfxVolSlider_value_changed(Save.game_data.sfx_vol)
	#check if there is a username
	if Save.game_data.username == "":
		usernameAsk.popup_centered()
		usernameInput.grab_focus()
		


"""
/*
* @pre called for every frame inside of the game
* @post detects user input
* @param delta -> float (time)
* @return None
*/
"""
func _process(_delta): #if you want to use delta, then change it to delta
	if Input.is_action_just_pressed("ui_cancel"):
		startButton.grab_focus()

"""
/*
* @pre Start Button is pressed
* @post Scene change to start of game
* @param None
* @return None
*/
"""
func _on_Start_pressed():
	SceneTrans.change_scene("res://Scenes/startArea/startArea.tscn")

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
	settingsMenu.popup_centered_ratio()

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


func _on_askForUsername_confirmed():
	settingsMenu._on_usernameInput_text_entered(usernameInput.text)
