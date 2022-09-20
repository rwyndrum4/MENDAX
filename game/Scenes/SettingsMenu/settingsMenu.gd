#based on tutorial provided by https://www.youtube.com/watch?v=cQkEPej_gRU

extends Popup

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
	#instancing Master Volume
	masterVolSlider.value = Save.game_data.master_vol
	#instancing Mouse Sens
	mouseSlider.value = Save.game_data.mouse_sens
	

#called when the display options dropdown options are pressed
func _on_DisplayOptionsButton_item_selected(index):
	GlobalSettings.toggle_fullscreen(true if index == 1 else false)


#called when the vsync button is pressed
func _on_VsyncButton_toggled(button_pressed):
	GlobalSettings.toggle_vsync(button_pressed)


#called when the display fps button is pressed 
func _on_DisplayFpsButton_toggled(button_pressed):
	GlobalSettings.toggle_fps_display(button_pressed)

#called when the fps slider is moved
func _on_MaxFpsSlider_value_changed(value):
	GlobalSettings.set_max_fps(value)
	maxFpsVal.text = str(value) if value < maxFpsSlider.max_value else "Max"
	
#called when the bloom button is pressed
func _on_BloomButton_toggled(button_pressed):
	GlobalSettings.toggle_bloom(button_pressed)

#called when the brightness slider is moved
func _on_BrightnessSlider_value_changed(value):
	GlobalSettings.update_brightness(value)

##called when the master volume slider is moved
#func _on_MasterVolSlider_value_changed(value):
#	pass
#
##called when the music volume slider is moved
#func _on_MusicVolSlider_value_changed(value):
#	pass # Replace with function body.
#
#
#func _on_SfxVolSlider_value_changed(value):
#	pass # Replace with function body.


func _on_MouseSensSlider_value_changed(value):
	GlobalSettings.update_mouse_sens(value)
	mouseVal.text = str(value)
