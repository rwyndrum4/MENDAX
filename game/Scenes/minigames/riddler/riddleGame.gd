"""
* Programmer Name - Freeman Spray and Mohit Garg
* Description - Code for controlling the Riddle minigame
* Date Created - 10/14/2022
* Date Revisions:
	10/16/2022 - 
	10/19/2022 -Added hidden item detector functionality -Mohit Garg
	10/22/2022-Added hidden item detector for multiple hints-Mohit Garg
"""
extends Control

# Member Variables
var in_menu = false
onready var settingsMenu = $GUI/SettingsMenu
onready var myTimer: Timer = $GUI/Timer
onready var timerText: Label = $GUI/Timer/timerText
onready var textBox = $GUI/textBox
onready var hintbox=$GUI/show_letter
onready var itemarray=[] #determines if items have been found
onready var hint="person";
onready var currenthints=""; #keeps track of currenhints found
onready var hintlength=0#keeps track of hintlength to give random letter clues

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
	# warning-ignore:return_value_discarded
	GlobalSignals.connect("inputText", self, "chatbox_submit")
	init_hiddenitems() #initalizes hidden items array and other things needed
	textBox.queue_text("Please enter the answer in the chat once you have it, there are hints hidden here if you need them (:")

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
* @pre Called in ready function before minigame
* @postInitalizes itemarray to 0s indicating no items have been found
* @param None
* @return None
*/
"""
func init_hiddenitems():
	hintlength=hint.length()
	for i in hintlength:
		itemarray.append(0)

"""
/*
* @pre Called when player enters hidden item area
* @post If item hasn't been found alerts player item is nearby
* @param Player
* @return None
*/
"""
func enterarea(spritepath,itemnumber):
	$Player/Labelarea.hide()
	if itemarray[itemnumber-1]==0: #means item has not been found
		spritepath.show()
		var rng = RandomNumberGenerator.new()
		var index=rng.randi_range(0, hintlength-1)
		var letter=hint[index];
		currenthints=str(currenthints)+letter;
		$Player/Hints.text += " " + letter
		if hintlength==1:
			hintbox.window_title=str(letter)+" is in the word. All hints have been found."; #all hints found
		else:
			hintbox.window_title=str(letter)+" is in the word"; #sets hint to letter given
		hintbox.popup()
		#erases letter from hint so it cannot be given again
		hint.erase(index,1)
		if hintlength!=0:
			hintlength=hintlength-1;#hintlength decreased as one letter given as hint
		itemarray[itemnumber-1]=1; #item has been found


"""
/*
* @pre Called when player enters hidden item area function declared for all 6 items
* @post If item hasn't been found alerts player item is nearby
* @param Player
* @return None
*/
"""
func _on_item1area_body_entered(_body:PhysicsBody2D)->void:
	if itemarray[0]==0:
		$Player/Labelarea.show()
func _on_item2area_body_entered(_body:PhysicsBody2D)->void:
	if itemarray[1]==0:
		$Player/Labelarea.show()
func _on_item3area_body_entered(_body:PhysicsBody2D)->void:
	if itemarray[2]==0:
		$Player/Labelarea.show()
func _on_item4area_body_entered(_body:PhysicsBody2D)->void:
	if itemarray[3]==0:
		$Player/Labelarea.show()
func _on_item5area_body_entered(_body:PhysicsBody2D)->void:
	if itemarray[4]==0:
		$Player/Labelarea.show()
func _on_item6area_body_entered(_body:PhysicsBody2D)->void:
	if itemarray[5]==0:
		$Player/Labelarea.show()
"""
/*
* @pre Called when player exits area near item called for all 6 items
* @post Hides message alerting player they are near item
* @param Player
* @return None
*/
"""
func _on_item1area_body_exited(_body:PhysicsBody2D)->void:
	$Player/Labelarea.hide()
func _on_item2area_body_exited(_body:PhysicsBody2D)->void:
	$Player/Labelarea.hide()
func _on_item3area_body_exited(_body:PhysicsBody2D)->void:
	$Player/Labelarea.hide()
func _on_item4area_body_exited(_body:PhysicsBody2D)->void:
	$Player/Labelarea.hide()
func _on_item5area_body_exited(_body:PhysicsBody2D)->void:
	$Player/Labelarea.hide()
func _on_item6area_body_exited(_body:PhysicsBody2D)->void:
	$Player/Labelarea.hide()

"""
/*
* @pre Called when player finds hidden item called for all 6 items
* @post Hides hidden item area label and shows hidden item along with alerting the player they have found the item
* @param Player
* @return None
*/
"""
func _on_item1_body_entered(_body:PhysicsBody2D)->void:
	if itemarray[0]==0:
		enterarea($item1/Sprite,1)
func _on_item2_body_entered(_body:PhysicsBody2D)->void:
	if itemarray[1]==0:
		enterarea($item2/Sprite,2)
func _on_item3_body_entered(_body:PhysicsBody2D)->void:
	if itemarray[2]==0:
		enterarea($item3/Sprite,3)
func _on_item4_body_entered(_body:PhysicsBody2D)->void:
	if itemarray[3]==0:
		enterarea($item4/Sprite,4)
func _on_item5_body_entered(_body:PhysicsBody2D)->void:
	if itemarray[4]==0:
		enterarea($item5/Sprite,5)
func _on_item6_body_entered(_body:PhysicsBody2D)->void:
	if itemarray[5]==0:
		enterarea($item6/Sprite,6)
"""
/*
* @pre Called when player has found item and is leaving called for all 6 items
* @post Hides hidden item  and label so they aren't shown again
* @param Player
* @return None
*/
"""
func _on_item1_body_exited(_body:PhysicsBody2D)->void:
	$item1/Sprite.hide()
	hintbox.hide()
func _on_item2_body_exited(_body:PhysicsBody2D)->void:
	$item2/Sprite.hide()
	hintbox.hide()
func _on_item3_body_exited(_body:PhysicsBody2D)->void:
	$item3/Sprite.hide()
	hintbox.hide()
func _on_item4_body_exited(_body:PhysicsBody2D)->void:
	$item4/Sprite.hide()
	hintbox.hide()
func _on_item5_body_exited(_body:PhysicsBody2D)->void:
	$item5/Sprite.hide()
	hintbox.hide()
func _on_item6_body_exited(_body):
	$item6/Sprite.hide()
	hintbox.hide()
