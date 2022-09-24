extends Control


# Declare member variables here. Examples:
onready var settingsMenu = $SettingsMenu
onready var fpsLabel = $fpsLabel


# Called when the node enters the scene tree for the first time.
func _ready():
	$VBoxContainer/Start.grab_focus()
	fpsLabel._on_fps_displayed(Save.game_data.display_fps)


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass


func _on_Start_pressed():
	pass # Replace with function body.


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
