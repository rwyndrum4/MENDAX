"""
* Programmer Name - Freeman Spray
* Description - Code that designates a 'Bezier' (light holder) object
* Date Created - 2/7/2023
* Citations - I referenced https://godotengine.org/qa/88049/how-to-change-sprite-from-code to remember how to set textures in code
* Date Revisions:
* Known bugs:
"""
extends StaticBody2D

var _in_radius
var _id
var _lit

# Called when the node enters the scene tree for the first time.
func _ready():
	_in_radius = -1
	_lit = false
	
"""
/*
* @pre An input of any sort
* @post None
* @param Takes in an event
* @return If event is 'accept' received while in the activation radius, ignites the torch
*/
"""
func _input(_ev):
	if _in_radius == _id:
		if Input.is_action_just_pressed("ui_accept",false) and not Input.is_action_just_pressed("ui_enter_chat") and not _lit:
			$Light2D.show()
			$TileTexture.set("texture", preload("res://Assets/tiles/TilesCorrected/BezierLit.png"))
			$FireHitbox.set("disabled", false)
			Global.progress+=1
			_lit = true
			

"""	
* @pre Called when player enters the bezier's Area2D zone
* @post sets _in_radius to the _id of the bezier (for interactability purposes)
* @param body -> body of the collider. Must be player in order to trigger a change.
* @return None
*/
"""
func _on_ActivationRadius_body_entered(body):
	if body.name == "Player":
		_in_radius = _id

"""	
* @pre Called when player exits the bezier's Area2D zone
* @post sets _in_radius to -1 (for interactability purposes)
* @param body -> body of the collider. Must be player in order to trigger a change.
* @return None
*/
"""
func _on_ActivationRadius_body_exited(body):
	if body.name == "Player":
		_in_radius = -1
