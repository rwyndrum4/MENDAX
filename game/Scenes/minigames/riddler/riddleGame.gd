

"""
* Programmer Name - Freeman Spray and Mohit Garg
* Description - Code for controlling the Riddle minigame
* Date Created - 10/14/2022
* Date Revisions:
	10/16/2022 - 
	10/19/2022 -Added hidden item detector functionality -Mohit Garg
"""
extends Control

# Member Variables
var in_menu = false
onready var settingsMenu = $GUI/SettingsMenu
onready var myTimer: Timer = $GUI/Timer
onready var timerText: Label = $GUI/Timer/timerText
onready var textBox = $GUI/textBox
onready var itemfound=false #determines if item is found

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
	#This is how you queue text to the textbox queue
	textBox.queue_text("What walks on four legs in the morning, two legs in the afternoon, and three in the evening?")
	# warning-ignore:return_value_discarded
	GlobalSignals.connect("openChatbox", self, "chatbox_use")
	GlobalSignals.connect("inputText", self, "chatbox_submit")






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
	#DEBUG PURPOSES - REMOVE FOR FINAL GAME!!!
	#IF YOU PRESS P -> TIMER WILL REDUCE TO 3 SECONDS
	if Input.is_action_just_pressed("debug_key",false):
		myTimer.start(3)

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
	SceneTrans.change_scene("res://Scenes/startArea/EntrySpace.tscn")

func chatbox_use(value):
	if value:
		in_menu = true
		
func chatbox_submit(inText):
	if inText == "person":
		SceneTrans.change_scene("res://Scenes/startArea/EntrySpace.tscn")

"""
/*
* @pre Called when player enters hidden item area
* @post If item hasn't been found alerts player item is nearby
* @param Player
* @return None
*/
"""
func _on_item1area_body_entered(body:PhysicsBody2D)->void:
	if itemfound==false:
		$Player/Labelarea.show()
"""
/*
* @pre Called when player exits area near item
* @post Hides message alerting player they are near item
* @param Player
* @return None
*/
"""
func _on_item1area_body_exited(body):
	$Player/Labelarea.hide()
"""
/*
* @pre Called when player finds hidden item
* @post Hides hidden item area label and shows hidden item along with alerting the player they have found the item
* @param Player
* @return None
*/
"""
func _on_item1_body_entered(body:PhysicsBody2D)->void:
	$Player/Labelarea.hide()
	if itemfound==false:
		$Player/Labelitem.show()
		$item1/Sprite.show()
		itemfound=true;
	

"""
/*
* @pre Called when player has found item and is leaving
* @post Hides hidden item  and label so they aren't shown again
* @param Player
* @return None
*/
"""
func _on_item1_body_exited(body:PhysicsBody2D)->void:
	$item1/Sprite.hide()
	$Player/Labelitem.hide()



