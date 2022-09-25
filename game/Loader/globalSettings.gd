"""
* Programmer Name - Ben Moeller
* Description - Global file for controlling what happens when user changes
*	their settings in the options menu (called from settingsMenu.gd)
* Date Created - 9/17/2022
* Date Revisions:
	9/21/2022 - Removed bloom functionality (unneeded)
	9/24/2022 - Added function comments
* Citations:
	Based on tutorial from https://www.youtube.com/watch?v=cQkEPej_gRU
"""

extends Node

# Engine Signals - Most of these are just defined and not used as of yet
signal fpsDisplayed(value)
signal brightnessUpdated(value)
signal mouseSenseUpdated(value)

"""
/*
* @pre Function is called from within settingsMenu.gd
* @post function that is called when user wants to change their window version
* 	if value passed = true, game goes fullscreen
* 	if value passed = false, game goes windowed
* @param value -> boolean
* @return None
*/
"""
func toggle_fullscreen(value):
	OS.window_fullscreen = value
	Save.game_data.fullscreen_on = value
	Save.save_data()

"""
/*
* @pre Function is called from within settingsMenu.gd
* @post function to toggle vsync on and off
* 	if value = true, vsync on
* 	if value = false, vsync off
* @param value -> boolean
* @return None
*/
"""
func toggle_vsync(value):
	OS.vsync_enabled = value
	Save.game_data.vsync_on = value
	Save.save_data()

"""
/*
* @pre Function is called from within settingsMenu.gd
* @post function to toggle on the fps display
*	if value = true, display turns on
*	if value = false, it turns off
* @param value -> boolean
* @return None
*/
"""
func toggle_fps_display(value):
	emit_signal("fpsDisplayed",value)
	Save.game_data.display_fps = value
	Save.save_data()

"""
/*
* @pre Function is called from within settingsMenu.gd
* @post function to set the engine's max fps value
*	if user sets value to 500, set target fps to 0 -> this means unlimited fps
*	otherwise user sets fps value between 30 and 500
* @param value -> integer
* @return None
*/
"""
func set_max_fps(value):
	Engine.target_fps = value if value < 500 else 0
	Save.game_data.max_fps = Engine.target_fps if value < 500 else 500
	Save.save_data()

"""
/*
* @pre Function is called from within settingsMenu.gd
* @post function to change brigtness
*	not full implemented yet
* @param value -> integer
* @return None
*/
"""
func update_brightness(value):
	emit_signal("brightnessUpdated",value)
	Save.game_data.brightness = value
	Save.save_data()

"""
/*
* @pre Function is called from within settingsMenu.gd
* @post function to change mouse sens
*	not full implemented yet
* @param value -> integer
* @return None
*/
"""
func update_mouse_sens(value):
	emit_signal("mouseSenseUpdated",value)
	Save.game_data.mouse_sens = value
	Save.save_data()
