#Font Family from: https://poppyworks.itch.io/silver

"""
* Programmer Name - From citation, edited by Ben Moeller
* Description - Code for controlling the text box
* Date Created - 10/9/2022
* Citation - https://github.com/jontopielski/rpg-textbox-tutorial/blob/master/Textbox.gd
	Based on this code from the above github
* Date Revisions:
	10/9/2022 - Added properties to show when text is added and changed onready var paths
"""
extends CanvasLayer

# Member Variables
const CHAR_READ_RATE = 0.05

onready var textbox_container = $Container
onready var start_symbol = $Container/MarginContainer/HBoxContainer/Start
onready var end_symbol = $Container/MarginContainer/HBoxContainer/End
onready var text_box = $Container/MarginContainer/HBoxContainer/Text
onready var text_displayer = $Tween

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
				TextboxSignals.emit_signal("textbox_shift",true)
		State.READING:
			#if text is currently in process of being displayed and enter is
			#pressed, display all text and move to finished state
			if Input.is_action_just_pressed("ui_accept"):
				text_box.percent_visible = 1.0
				text_displayer.remove_all()
				end_symbol.text = "v"
				change_state(State.FINISHED)
		State.FINISHED:
			#if in finished state and enter is pressed, move to ready state
			#and hide textbox
			if Input.is_action_just_pressed("ui_accept"):
				change_state(State.READY)
				hide_textbox()
				TextboxSignals.emit_signal("textbox_shift",false)

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
#	match current_state:
#		State.READY:
#			print("Changing state to: State.READY")
#		State.READING:
#			print("Changing state to: State.READING")
#		State.FINISHED:
#			print("Changing state to: State.FINISHED")

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
	change_state(State.FINISHED)
