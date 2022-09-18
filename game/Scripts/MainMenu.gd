extends Control

# Member Variables
onready var settingsMenu = $SettingsMenu

# Called when the node enters the scene tree for the first time.
func _ready():
	$VBoxContainer/Start.grab_focus()


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass

#function that is called when the start button is pressed
func _on_Start_pressed():
	pass # Replace with function body.

#function that is called when the options button is pressed
func _on_Options_pressed():
	settingsMenu.popup_centered()

#function that is called when the market button is pressed
func _on_Market_pressed():
	pass # Replace with function body.

#function that is called when the tests button is pressed
func _on_Tests_pressed():
	pass # Replace with function body.

#function that is called when the quit button is pressed
func _on_Quit_pressed():
	get_tree().quit()
