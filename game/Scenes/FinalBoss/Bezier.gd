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
onready var myTimer: Timer = $Timer

# Called when the node enters the scene tree for the first time.
func _ready():
	_in_radius = -1
	_lit = 0
	
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
		if Input.is_action_just_pressed("ui_accept",false) and not Input.is_action_just_pressed("ui_enter_chat") and _lit == 0:
			myTimer.start(3)
			_lit = 1
			
"""
/*
* @pre Called when the timer hits 0
* @post None
* @param None
* @return String (text of current time left)
*/
"""
func _on_Timer_timeout():
	if _lit == 1:
		ServerConnection.send_besier_notif(_id)
		set_process_input(false) #no need for input now that lit
		$Light2D.show()
		$TileTexture.set("texture", preload("res://Assets/tiles/TilesCorrected/BezierLit.png"))
		$FireHitbox.set("disabled", false)
		Global.progress+=1
		_lit = 2

"""
/*
* @pre Called when someone else in server game lights a besier
* @post Sets the besier light textures
* @param None
* @return None
*/
"""
func someone_lit_besier():
	if _lit == 1:
		set_process_input(false) #no need for input now that lit
		$Light2D.show()
		$TileTexture.set("texture", preload("res://Assets/tiles/TilesCorrected/BezierLit.png"))
		$FireHitbox.set("disabled", false)
		Global.progress+=1
		_lit = 2

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
		if _lit == 1:
			_lit = 0
