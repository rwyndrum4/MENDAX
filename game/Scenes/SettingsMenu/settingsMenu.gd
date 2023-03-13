"""
* Programmer Name - Ben Moeller
* Description - File for controlling what happens when buttons/sliders are
*	pressed inside of the options menu
* Date Created - 9/17/2022
* Date Revisions:
	9/21/2022 - Removed bloom functionality (unneeded)
* Citations:
	Based on tutorial from https://www.youtube.com/watch?v=cQkEPej_gRU
"""

extends Popup

# Member Variables
var MASTER_VOLUME = 0 #corresponds to master volume bus
var MUSIC_VOLUME = 1 #corresponds to music volume bus
var SFX_VOLUME = 2 #corrsponds to sfx volume bus
var just_in_menu = false
var changing_username = false

# Video Settings
onready var displayOptions = $SettingsTabs/Video/MarginContainer/videoSettings/DisplayOptionsButton
onready var vsyncButton = $SettingsTabs/Video/MarginContainer/videoSettings/VsyncButton
onready var displayFpsButton = $SettingsTabs/Video/MarginContainer/videoSettings/DisplayFpsButton
onready var maxFpsVal = $SettingsTabs/Video/MarginContainer/videoSettings/FpsSlider/MaxFpsVal
onready var maxFpsSlider = $SettingsTabs/Video/MarginContainer/videoSettings/FpsSlider/MaxFpsSlider
onready var bloomButton = $SettingsTabs/Video/MarginContainer/videoSettings/BloomButton
onready var brightnessSlider = $SettingsTabs/Video/MarginContainer/videoSettings/Brightness/BrightnessSlider

# Audio Settings
onready var masterVolSlider = $SettingsTabs/Audio/MarginContainer/audioSettings/MasterVol/MasterVolSlider
onready var musicVolSlider = $SettingsTabs/Audio/MarginContainer/audioSettings/MusicVal/MusicVolSlider
onready var sfxVolSlider = $SettingsTabs/Audio/MarginContainer/audioSettings/SfxVol/SfxVolSlider

# Gameplay Settings
onready var mouseVal = $SettingsTabs/Gameplay/GameplaySettings/audioSettings/MouseSense/MouseVal
onready var mouseSlider = $SettingsTabs/Gameplay/GameplaySettings/audioSettings/MouseSense/MouseSensSlider
onready var usernameInput = $SettingsTabs/Gameplay/GameplaySettings/audioSettings/HBoxContainer/usernameInput

"""
/*
* @pre called when mainMenu is loaded (runs once)
* @post instances all of the user's saved settings
* @param None
* @return None
*/
"""
func _ready():
	#instnacing display option (Fullscreen or Windowed)
	displayOptions.select(1 if Save.game_data.fullscreen_on else 0)
	GlobalSettings.toggle_fullscreen(Save.game_data.fullscreen_on)
	#instancing Vsync options
	vsyncButton.pressed = Save.game_data.vsync_on
	#instancing Fps settings
	displayFpsButton.pressed = Save.game_data.display_fps
	#instancing Fps slider 
	maxFpsSlider.value = Save.game_data.max_fps
	#instancing bloom
	bloomButton.pressed = Save.game_data.bloom_on
	#instancing brightness
	brightnessSlider.value = Save.game_data.brightness
	#instancing Volume sliders
	masterVolSlider.value = Save.game_data.master_vol
	musicVolSlider.value = Save.game_data.music_vol
	sfxVolSlider.value = Save.game_data.sfx_vol
	#instancing Mouse Sens
	mouseSlider.value = Save.game_data.mouse_sens

func _process(_delta): #change to delta if using
	#checks if settings menu is currently being used
	if is_visible_in_tree():
		#Emit signal to tell player to stop moving
		GlobalSignals.emit_signal("openMenu",true)
		if not changing_username:
			change_settings_tabs()
		just_in_menu = true
	if not is_visible_in_tree() and just_in_menu:
		#Emit signal to tell player to start moving again
		GlobalSignals.emit_signal("openMenu",false)
		just_in_menu = false
"""
/*
* @pre called when the display options dropdown options are pressed
* @post calls toggle_fullscreen function in globalSettings.gd
* @param index -> integer
* @return None
*/
"""
func _on_DisplayOptionsButton_item_selected(index):
	GlobalSettings.toggle_fullscreen(true if index == 1 else false)

"""
/*
* @pre called when the vsync button is pressed
* @post calls toggle_vsync function in globalSettings.gd
* @param button_pressed -> boolean
* @return None
*/
"""
func _on_VsyncButton_toggled(button_pressed):
	GlobalSettings.toggle_vsync(button_pressed)

"""
/*
* @pre called when the display fps button is pressed
* @post calls toggle_fps_display function in globalSettings.gd
* @param button_pressed -> boolean
* @return None
*/
"""
func _on_DisplayFpsButton_toggled(button_pressed):
	GlobalSettings.toggle_fps_display(button_pressed)

"""
/*
* @pre called when the fps slider is moved
* @post calls set_max_fps function in globalSettings.gd
* @param button_pressed -> integer
* @return None
*/
"""
func _on_MaxFpsSlider_value_changed(value):
	GlobalSettings.set_max_fps(value)
	maxFpsVal.text = str(value) if value < maxFpsSlider.max_value else "Max"
	
"""
/*
* @pre called when the bloom button is pressed
* @post calls toggle_bloom function in globalSettings.gd
* @param button_pressed -> boolean

* @return None
*/
"""
func _on_BloomButton_toggled(button_pressed):
	GlobalSettings.toggle_bloom(button_pressed)

"""
/*
* @pre called when the brightness slider is moved
* @post calls update_brightness function in globalSettings.gd
* @param button_pressed -> integer
* @return None
*/
"""
func _on_BrightnessSlider_value_changed(value):
	GlobalSettings.update_brightness(value)

"""
/*
* @pre called when the mouse sens slider is moved
* @post calls update_mouse_sens function in globalSettings.gd
* @param button_pressed -> integer
* @return None
*/
"""
func _on_MouseSensSlider_value_changed(value):
	GlobalSettings.update_mouse_sens(value)
	mouseVal.text = str(value)

"""
/*
* @pre called when username focus is entered
* @post changes placeholder text and makes it so you can't move around in menu
* @param None
* @return None
*/
"""
func _on_usernameInput_focus_entered():
	usernameInput.placeholder_text = "ENTER to submit, Arrow Keys to exit"
	changing_username = true

"""
/*
* @pre called when username focus is exited
* @post changes placeholder text and makes it so you can move around in menu
* @param None
* @return None
*/
"""
func _on_usernameInput_focus_exited():
	usernameInput.placeholder_text = ""
	changing_username = false

"""
/*
* @pre called when username is submitted
* @post changes username if valid
* @param new_text -> String
* @return None
*/
"""
func _on_usernameInput_text_entered(new_text):
	if " " in new_text:
		var dialog = AcceptDialog.new()
		dialog.dialog_text = "No spaces in username please, change again in settings"
		dialog.window_title = "Invalid Username"
		dialog.connect('modal_closed', dialog, 'queue_free')
		add_child(dialog)
		dialog.popup_centered()
	else:
		GlobalSettings.update_username(new_text)
	usernameInput.text = ""

"""
/*
* @pre called when the master volume slider is moved
* @post calls update_volume function in globalSettings.gd with master param
* @param button_pressed -> integer
* @return None
*/
"""
func _on_MasterVolSlider_value_changed(value):
	GlobalSettings.update_volume(MASTER_VOLUME,value)

"""
/*
* @pre called when the master volume slider is moved
* @post calls update_volume function in globalSettings.gd with music param
* @param button_pressed -> integer
* @return None
*/
"""
func _on_MusicVolSlider_value_changed(value):
	GlobalSettings.update_volume(MUSIC_VOLUME,value)

"""
/*
* @pre called when the master volume slider is moved
* @post calls update_volume function in globalSettings.gd with sfx param
* @param button_pressed -> integer
* @return None
*/
"""
func _on_SfxVolSlider_value_changed(value):
	GlobalSettings.update_volume(SFX_VOLUME,value)

"""
/*
* @pre called when the quit button is pressed
* @post quits out of the game
* @param None
* @return None
*/
"""
func _on_quitButton_pressed():
	if ServerConnection.match_exists():
		ServerConnection.leave_match(ServerConnection._match_id)
		ServerConnection.leave_match_group()
	get_tree().quit()

"""
/*
* @pre called when the main menu button is pressed
* @post sends player to main menu
* @param None
* @return None
*/
"""
func _on_mainMenuButton_pressed():
	Global.state = Global.scenes.MAIN_MENU

"""
/*
* @pre called when you someone changes settings tabs with keyboard
* @post changes current tab
* @param None
* @return None
*/
"""
func change_settings_tabs():
	var tab: TabContainer = $SettingsTabs
	var current = tab.current_tab
	#detecting right
	if Input.is_action_just_released("ui_tab_right",false):
		if current < 3:
			tab.current_tab += 1
			grab_button(tab.current_tab)
	#detecting left
	if Input.is_action_just_released("ui_tab_left",false):
		if current > 0:
			tab.current_tab -= 1
			grab_button(tab.current_tab)

"""
/*
* @pre called from the change_settins_tabs function
* @post grabs the attention of the button/object at the top of the current tab
* @param current_tab -> int (current tab that user is on)
* @return None
*/
"""
func grab_button(current_tab):
	if current_tab == 0:
		get_node("SettingsTabs/Video/MarginContainer/videoSettings/DisplayOptionsButton").grab_focus()
	elif current_tab == 1:
		get_node("SettingsTabs/Audio/MarginContainer/audioSettings/MasterVol/MasterVolSlider").grab_focus()
	elif current_tab == 2:
		get_node("SettingsTabs/Gameplay/GameplaySettings/audioSettings/MouseSense/MouseSensSlider").grab_focus()
	elif current_tab == 3:
		get_node("SettingsTabs/Exit/exitSettings/GridContainer/quitButton").grab_focus()
