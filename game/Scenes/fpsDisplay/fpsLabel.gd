"""
* Programmer Name - Ben Moeller
* Description - Script file for controlling the fps display button
* Date Created - 9/20/2022
* Date Revisions:
	9/24/2022 - Added function comments
* Citations:
	Based on tutorial from https://www.youtube.com/watch?v=cQkEPej_gRU
"""
extends Label

"""
/*
* @pre None
* @post Function that first plays when the fps_label enters the scene 
* 	aka connects the signal from globalSettings.gd
* @param None
* @return None
*/
"""
func _ready():
	GlobalSettings.connect("fpsDisplayed", self, "_on_fps_displayed")

"""
/*
* @pre None
* @post changes the text value of the fps value to the user's current framerate
* @param delta -> float time value godot provides
* @return None
*/
"""
func _process(delta):
	text = "FPS: %s" % [Engine.get_frames_per_second()]

"""
/*
* @pre None
* @post determines whether the fps display should be showed based on
* 	the boolean value passed in
* @param value -> boolean value 
* @return None
*/
"""
func _on_fps_displayed(value):
	visible = value
