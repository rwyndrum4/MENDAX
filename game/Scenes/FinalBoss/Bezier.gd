"""
* Programmer Name - Freeman Spray
* Description - Code that designates a 'Bezier' (light holder) object
* Date Created - 2/7/2023
* Citations - I referenced https://godotengine.org/qa/88049/how-to-change-sprite-from-code to remember how to set textures in code
* Date Revisions:
"""
extends StaticBody2D

var _in_radius = false


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.
	
"""
/*
* @pre An input of any sort
* @post None
* @param Takes in an event
* @return If event is 'accept' received while in the activation radius, ignites the torch
*/
"""
func _input(_ev):
	if _in_radius:
		if Input.is_action_just_pressed("ui_accept",false) and not Input.is_action_just_pressed("ui_enter_chat"):
			$Light2D.show()
			$TileTexture.set("texture", preload("res://Assets/tiles/TilesCorrected/BezierLit.png"))

"""	
* @pre Called when player enters the bezier's Area2D zone
* @post sets _in_radius to true (for interactability purposes)
* @param _body -> body of the player
* @return None
*/
"""
func _on_ActivationRadius_body_entered(_body):
	_in_radius = true

"""	
* @pre Called when player exits the bezier's Area2D zone
* @post sets _in_radius to false (for interactability purposes)
* @param _body -> body of the player
* @return None
*/
"""
func _on_ActivationRadius_body_exited(_body):
	_in_radius = false
