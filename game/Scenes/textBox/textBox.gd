#Font Family from: https://poppyworks.itch.io/silver

"""
* Programmer Name - From citation, edited by Ben Moeller
* Description - Code for controlling the text box
* Date Created - 10/9/2022
* Citation - https://github.com/jontopielski/rpg-textbox-tutorial/blob/master/Textbox.gd
	Based on this code from the above github
* Date Revisions:
	10/9/2022 - Added properties to show when text is added and changed onready var paths
	1/28/2023 - Added sfx for text box "typing"
"""
extends CanvasLayer

# Member Variables
const CHAR_READ_RATE = 0.05

onready var textbox_container = $Container
onready var start_symbol = $Container/MarginContainer/HBoxContainer/Start
onready var end_symbol = $Container/MarginContainer/HBoxContainer/End
onready var text_box = $Container/MarginContainer/HBoxContainer/Text
onready var text_displayer = $Tween
onready var dialogue = $dialogue

enum State {
	READY,
	READING,
	FINISHED
}

var current_state = State.READY
var text_queue = []

"""
/*
* @pre Called once to initialize text box
* @post hides the textbox upon entering scene
* @param None
* @return None
*/
"""
func _ready():
	#print("Starting state: State.READY")
	hide_textbox()

"""
/*
* @pre Called for every frame
* @post Keeps track of the current state of the FSM
* @param _delta -> time constraint that can be optionally used
* @return None
*/
"""
func _process(_delta): #change to delta if used
	match current_state:
		State.READY:
			#if in ready state and the queue is not empty, display the text
			if !text_queue.empty():
				display_text()
				GlobalSignals.emit_signal("textbox_shift",true)
				# Play dialogue sounds if in scenes that require them
				if Global.state == Global.scenes.RIDDLER_MINIGAME:
					$RiddlerDialogue.play()
				elif Global.state == Global.scenes.ARENA_MINIGAME:
					$ArenaDialogue.play()
			else:
				# Stop any playing dialogue
				if Global.state == Global.scenes.RIDDLER_MINIGAME:
					$RiddlerDialogue.stop()
				elif Global.state == Global.scenes.ARENA_MINIGAME:
					$ArenaDialogue.stop()
		State.READING:
			#if text is currently in process of being displayed and enter is
			#pressed, display all text and move to finished state
			if Input.is_action_just_pressed("ui_accept"):
				dialogue.stop()
				# Stop any playing dialogue
				if Global.state == Global.scenes.RIDDLER_MINIGAME:
					$RiddlerDialogue.stop()
				elif Global.state == Global.scenes.ARENA_MINIGAME:
					$ArenaDialogue.stop()
				$accept.play()
				text_box.percent_visible = 1.0
				text_displayer.remove_all()
				end_symbol.text = "v"
				change_state(State.FINISHED)
				
		State.FINISHED:
			#if in finished state and enter is pressed, move to ready state
			#and hide textbox
			if Input.is_action_just_pressed("ui_accept"):
				change_state(State.READY)
				# Stop any playing dialogue
				if Global.state == Global.scenes.RIDDLER_MINIGAME:
					$RiddlerDialogue.stop()
				elif Global.state == Global.scenes.ARENA_MINIGAME:
					$ArenaDialogue.stop()
				dialogue.stop()
				$accept.play()
				hide_textbox()
				GlobalSignals.emit_signal("textbox_shift",false)
				if text_queue.empty():
					GlobalSignals.emit_signal("textbox_empty")
"""
/*
* @pre None
* @post returns the current state of the textbox
* @param None
* @return None
*/
"""
func get_state() -> String:
	if current_state == State.READY:
		return "ready"
	elif current_state == State.READING:
		return "reading"
	elif current_state == State.FINISHED:
		return "finished"
	else:
		return ""

"""
/*
* @pre Called when wanting to add text to box
* @post Pushes text to the back of the queue
* @param next_text -> String
* @return None
*/
"""
func queue_text(next_text):
	#pushes text onto queue
	text_queue.push_back(next_text)

"""
/*
* @pre None
* @post None
* @param 
* @return Returns task list
*/
"""
func queue_text_length():
	#return text length
	return len(text_queue)

"""
/*
* @pre None
* @post Resets current textbox and hides from screen
* @param None
* @return None
*/
"""
func hide_textbox():
	start_symbol.text = ""
	end_symbol.text = ""
	text_box.text = ""
	textbox_container.hide()

"""
/*
* @pre None
* @post Iniitializes start symbol and unhides the textbox
* @param None
* @return None
*/
"""
func show_textbox():
	start_symbol.text = "*"
	#show both the scene and text container
	show()
	textbox_container.show()

"""
/*
* @pre There needs to be text inside of the global queue (text_queue)
* @post Displays text onto the text box
* @param None
* @return None
*/
"""
func display_text():
	var next_text = text_queue.pop_front()
	text_box.text = next_text
	text_box.percent_visible = 0.0
	show_textbox()
	change_state(State.READING)
	#Next two lines is what makes text slowly show up in textbox
	text_displayer.interpolate_property(text_box, "percent_visible", 0.0, 1.0, len(next_text) * CHAR_READ_RATE, Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
	dialogue.play()
	text_displayer.start()
	

"""
/*
* @pre None
* @post changes current_state to whatever state is passed in
* @param next_state -> enum value (see the global state Enum above)
* @return None
*/
"""
func change_state(next_state):
	current_state = next_state

"""
/*
* @pre None
* @post Will take all lines inside of a text file and apply queue_text to them
* @param file_name -> String (name of the file in terms of godot)
* EXAMPLE: "res://Scenes/startArea/test.txt"
* You won't be able to see text file in godot but its there
* @return None
*/
"""
func queue_file(file_name: String):
	var f = File.new()
	f.open(file_name, File.READ)
	while not f.eof_reached():
		var line = f.get_line()
		if line != "":
			queue_text(line)
	f.close()

"""
/*
* @pre Called whenever the tween finishes displaying the text
* @post Adds end symbol and changes state to finshed
* @param None
* @return None
*/
"""
func _on_Tween_tween_completed(_object, _key): #remove underscores if want to use variables
	end_symbol.text = ">"
	# Stop any playing dialogue
	if Global.state == Global.scenes.RIDDLER_MINIGAME:
		$RiddlerDialogue.stop()
	elif Global.state == Global.scenes.ARENA_MINIGAME:
		$ArenaDialogue.stop()
	dialogue.stop()
	change_state(State.FINISHED)
