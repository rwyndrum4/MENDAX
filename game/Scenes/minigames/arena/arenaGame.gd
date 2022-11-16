"""
* Programmer Name - Freeman Spray
* Description - Code for controlling the Arena minigame
* Date Created - 11/5/2022
* Date Revisions: 11/12/2022 - added physics process to manage Skeleton positioning
*				  11/13/2022 - got Skeleton to track a player
* Known bugs: physics process crashes the game if skeleton has been destroyed.
			  skeleton movement is highly unreliable, stopping and starting seemingly at random
"""
extends Control

# Member Variables
var in_menu = false
onready var settingsMenu = $GUI/SettingsMenu
onready var myTimer: Timer = $GUI/Timer
onready var timerText: Label = $GUI/Timer/timerText
onready var player = $Player
onready var swordPivot = $Player/Sword/pivot
onready var sword = $Player/Sword


"""
/*
* @pre Called when the node enters the scene tree for the first time.
* @post updates starts the timer
* @param None
* @return None
*/
"""
func _ready():
	myTimer.start(90)
	# warning-ignore:return_value_discarded
	GlobalSignals.connect("openChatbox", self, "chatbox_use")


"""
/*
* @pre Called for every frame
* @post updates timer and changes scenes if player presses enter and is in the zone
* @param _delta -> time variable that can be optionally used
* @return None
*/
"""
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta): #change to delta if used
	check_settings()
	timerText.text = convert_time(myTimer.time_left)
	if sword.direction == "right":
		swordPivot.position = player.position + Vector2(55.5,-10)
	if sword.direction == "left":
		swordPivot.position = player.position + Vector2(-55.5,-10)

"""
/*
* @pre Called every frame
* @post x an y velocity of the Skeleton is updated to move towards the player (if the player is within it's Search range)
* @param delta : elapsed time (in seconds) since previous frame. Should be constant across sequential calls
* @return None
*/
"""		
func _physics_process(delta):
	if $Skeleton.targetFound:
		$Skeleton.velocity = $Skeleton.move_and_slide($Skeleton.velocity.move_toward(0.7*(player.position - $Skeleton.position), 500*delta))
	else:
		$Skeleton.velocity = $Skeleton.move_and_slide($Skeleton.velocity.move_toward(0.7*Vector2.ZERO, 500*delta))
		
"""
/*
* @pre An input of any sort
* @post None
* @param Takes in an event
* @return None
*/
"""
func _input(ev):
	#DEBUG PURPOSES - REMOVE FOR FINAL GAME!!!
	#IF YOU PRESS P -> TIMER WILL REDUCE TO 3 SECONDS
	if Input.is_action_just_pressed("timer_debug_key",false):
		myTimer.start(3)
	#IF YOU PRESS O (capital 'o') -> TIMER WILL INCREASE TO ARBITRARILY MANY SECONDS
	if Input.is_action_just_pressed("extend_timer_debug_key",false):
		myTimer.start(30000)
		
"""
/*
* @pre Called for every frame inside process function
* @post Opens and closes settings when escape is pressed
* @param None
* @return None
*/
"""
func check_settings():
	if Input.is_action_just_pressed("ui_cancel",false) and not in_menu:
		settingsMenu.popup_centered_ratio()
		in_menu = true
	elif Input.is_action_just_pressed("ui_cancel",false) and in_menu:
		settingsMenu.hide()
		in_menu = false

"""
/*
* @pre Called when need to convert seconds to MIN:SEC format
* @post Returns string of current time
* @param time_in -> float 
* @return String (text of current time left)
*/
"""
func convert_time(time_in:float) -> String:
	var rounded_time = int(time_in)
	var minutes: int = rounded_time/60
	var seconds: int = rounded_time - (minutes*60)
	return str(minutes,":",seconds)

"""
/*
* @pre Called when the timer hits 0
* @post Changes scene to minigame
* @param None
* @return String (text of current time left)
*/
"""
func _on_Timer_timeout():
	Global.state = Global.scenes.CAVE

func chatbox_use(value):
	if value:
		in_menu = true


func _on_mySearchBox_body_entered(_body:PhysicsBody2D):
	$Skeleton.targetFound = true


func _on_myLostBox_body_exited(body):
	$Skeleton.targetFound = false
