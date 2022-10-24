"""
* Programmer Name - Freeman Spray, Ben Moeller
* Description - Code for controlling what happens in the entry space scene
* Date Created - 10/3/2022
* Date Revisions:
	10/8/2022 - Added the ability to go into settings from scene with enter key
"""
extends Control

# Member Variables
var in_exit = false
var in_menu = false
onready var instructions: Label = $exitCaveArea/exitDirections
onready var settingsMenu = $GUI/SettingsMenu
onready var myTimer: Timer = $GUI/Timer
onready var timerText: Label = $GUI/Timer/timerText
onready var textBox = $GUI/textBox
onready var playerCam = $Player/Camera2D
onready var transCam = $Path2D/PathFollow2D/camTrans
onready var riddler = $riddler

#signals
signal textWait()


"""
/*
* @pre Called when the node enters the scene tree for the first time.
* @post updates starts the timer
* @param None
* @return None
*/
"""
func _ready():
	#hide cave instructions at start
	instructions.hide()
	
	# warning-ignore:return_value_discarded
	GlobalSignals.connect("openChatbox", self, "chatbox_use")
	#scene animation for entering cave(for first time)
	if Global.entry == 0:
		#Insert Dialogue: "Oh who do we have here?" or something similar
		
		Global.entry = 1
		transCam.current = true
		$Player.set_physics_process(false)
		#Begin scene dialogue
		textBox.queue_text("Oh who do we have here?")
		$Path2D/AnimationPlayer.play("BEGIN")
		yield($Path2D/AnimationPlayer, "animation_finished")
		textBox.queue_text("Ooga booga. Riddle here and you got so and so time")
		
		connect("textWait", self, "_finish_anim")
		Global.in_anim = 1;
	else:
		myTimer.start(90)

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

"""
/*
* @pre None
* @post Starts timer for minigame, sets playerCam to current, and sets physic_process to True
* @param None
* @return None
*/
"""
func _finish_anim():
	var t = Timer.new()
	t.set_wait_time(1)
	t.set_one_shot(false)
	self.add_child(t)
		
	t.start()
	yield(t, "timeout")

	$Path2D/AnimationPlayer.play_backwards("BEGIN")
	yield($Path2D/AnimationPlayer, "animation_finished")
	t.start()
	yield(t, "timeout")
	
	#start timer
	textBox.queue_text("Time starts now!")
	myTimer.start(90)
	
	#remove jester
	riddler.queue_free()
	
	t.queue_free()
	$Player.set_physics_process(true)
	playerCam.current = true

"""
/*
* @pre An input of any sort
* @post None
* @param Takes in an event
* @return None
*/
"""
func _input(ev):
	if Input.is_key_pressed(KEY_ENTER) and not ev.echo:
		if Global.in_anim == 1:
			Global.in_anim = 0
			emit_signal("textWait")
	if in_exit:
		if Input.is_action_just_pressed("ui_accept",false) and not Input.is_action_just_pressed("ui_enter_chat"):
			# warning-ignore:return_value_discarded
			Global.state = Global.scenes.MAIN_MENU #change scene to main menu
	#DEBUG PURPOSES - REMOVE FOR FINAL GAME!!!
	#IF YOU PRESS P -> TIMER WILL REDUCE TO 3 SECONDS
	if Input.is_action_just_pressed("debug_key",false):
		myTimer.start(3)
"""
/*
* @pre Ca	velocity = move_and_slide(velocity)lled when player enters the Area2D zone
* @post shows instructions on screen and sets in_cave to true
* @param _body -> body of the player
* @return None
*/
"""
func _on_exitCaveArea_body_entered(_body: PhysicsBody2D): #change to body if want to use
	instructions.show()
	in_exit = true
	
"""
/*
* @pre Called when player exits the Area2D zone
* @post hides instructions on screen and sets in_cave to false
* @param _body -> body of the player
* @return None
*/
"""
func _on_exitCaveArea_body_exited(_body: PhysicsBody2D): #change to body if want to use
	in_exit = false
	instructions.hide()

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
	#change scene to riddler minigame
	Global.state = Global.scenes.RIDDLER_MINIGAME

"""
/*
* @pre None
* @post Sets in_menu to true
* @param value
* @return None
*/
"""
func chatbox_use(value):
	if value:
		in_menu = true
