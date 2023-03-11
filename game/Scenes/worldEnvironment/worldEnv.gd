"""
* Programmer Name - Ben Moeller
* Description - File for controlling the wolrd environment (aka brightness and bloom of scene)
* Date Created - 9/25/2022
* Date Revisions:
* Citations:
	Based on tutorial from https://www.youtube.com/watch?v=cQkEPej_gRU
"""

extends WorldEnvironment

"""
/*
* @pre called when environment is loaded
* @post connects signals from globalSettings.gd
* @param None
* @return None
*/
"""
func _ready():
	# warning-ignore:return_value_discarded
	GlobalSettings.connect("bloomToggled",Callable(self,"_on_bloom_toggled"))
	# warning-ignore:return_value_discarded
	GlobalSettings.connect("brightnessUpdated",Callable(self,"_on_brightness_toggled"))

"""
/*
* @pre called when received bloom signal
* @post changes glow_enabled to valule passed in
* @param value -> boolean
* @return None
*/
"""
func _on_bloom_toggled(value):
	environment.glow_enabled = value

"""
/*
* @pre called when received brightness signal
* @post changes adjust_brightness to valule passed in
* @param value -> float (0.2 - 2.0)
* @return None
*/
"""
func _on_brightness_toggled(value):
	environment.adjustment_brightness = value
