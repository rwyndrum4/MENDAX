"""
* Programmer Name - Freeman Spray
* Description - Code for controlling the Arena minigame
* Date Created - 11/5/2022
* Date Revisions:
"""
extends Control

# Member Variables
var in_menu = false
onready var settingsMenu = $GUI/SettingsMenu
onready var myTimer: Timer = $GUI/Timer
onready var timerText: Label = $GUI/Timer/timerText
onready var textBox = $GUI/textBox
onready var transCam = $Path2D/PathFollow2D/camTrans
onready var playerCam = $Player/Camera2D

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
	#myTimer.start(90)
	
	# warning-ignore:return_value_discarded
	GlobalSignals.connect("openChatbox", self, "chatbox_use")
	
	
	#scene animation for entering cave(for first time)
	if Global.entry == 0:

		var t = Timer.new()
		t.set_wait_time(1)
		t.set_one_shot(false)
		self.add_child(t)
			
		
		
		Global.entry = 1
		transCam.current = true
		$Player.set_physics_process(false)
		#Begin scene dialogue
		textBox.queue_text("Welcome to the arena")
		t.start()
		yield(t, "timeout")
		t.queue_free()
		$Path2D/AnimationPlayer.play("BEGIN")
		yield($Path2D/AnimationPlayer, "animation_finished")
		#This is how you queue text to the textbox queue
		textBox.queue_text("In order to pass, you must defeat every enemy. ")
		textBox.queue_text("If you fail to defeat the enemies within the time allotted, they will become vastly more powerful.")
		textBox.queue_text("Whenever a player dies, the timer will reset. Note that this does not help if the time has already run out.")
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
	if Input.is_key_pressed(KEY_ENTER) and not ev.echo and textBox.queue_text_length() == 0:
		if Global.in_anim == 1:
			Global.in_anim = 0
			emit_signal("textWait")

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
