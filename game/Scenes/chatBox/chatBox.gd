"""
* Programmer Name - Ben Moeller
* Description - File for controlling the in game chatbox
* Date Created - 10/12/2022
* Date Revisions:
"""

extends Control

signal message_sent(msg,is_whisper,username)

# set to true if you want to test chatbox locally
var DEBUG_ON = true

# Member Variables
onready var chatLog = $textHolder/pastText
onready var playerInput = $textHolder/inputField/playerInput

enum group_types {
	GENERAL,
	WHISPER
}

#Boolean that says if user is using chatbox
var in_chatbox = false
#Modulate values
var MODULATE_MIN = 140
var MODULATE_MAX = 255
var CHARACTER_LIMIT = 256
#Colors
var channel_colors:Dictionary = {
	"Green": "#51f538",
	"Blue": "#6aeaff",
	"White": "#ffffff"
}
#Placeholder texts
var current_pt: int = 0
var MAX_PT: int = 3
var placeholder_texts = [
	" SHIFT+ENTER to chat, Esc to exit",
	" Press TAB to cycle messages",
	" To send to everyone, input a message",
	" /whisper player_name message"
]

"""
/*
* @pre called once to initialize scene
* @post Sets current chat type
* @param None
* @return None
*/
"""
func _ready():
	playerInput.placeholder_text = "SHIFT+ENTER to chat, Esc to exit"
	modulate.a8 = MODULATE_MIN

"""
/*
* @pre called whenever the chatbox is interacted with
* @post Enters chatbox if "SHIFT+ENTER" is pressed
* 	Exits chatbox if "Esc" is pressed
*	Changes chat type if tab is pressed
* @param event -> Input Event
* @return None
*/
"""
func _input(event):
	if event is InputEventKey:
		if event.pressed and Input.is_action_just_pressed("ui_enter_chat"):
			playerInput.grab_focus()
			in_chatbox = true
			modulate.a8 = MODULATE_MAX
			current_pt = 1
			playerInput.placeholder_text = placeholder_texts[current_pt]
			GlobalSignals.emit_signal("openChatbox",true)
		if event.pressed and Input.is_action_just_pressed("ui_cancel"):
			playerInput.release_focus()
			in_chatbox = false
			modulate.a8 = MODULATE_MIN
			current_pt = 0
			playerInput.placeholder_text = placeholder_texts[current_pt]
			GlobalSignals.emit_signal("openChatbox",false)
		if event.pressed and Input.is_action_just_pressed("ui_swap_chat_groups") and in_chatbox:
			if playerInput.text == "":
				current_pt += 1
				playerInput.placeholder_text = placeholder_texts[current_pt]
				if current_pt == MAX_PT:
					current_pt = 1
			else:
				if playerInput.text in "/whisper":
					playerInput.text = "/whisper "
"""
/*
* @pre called when user enters message into the chatbox
* @post formats text and puts it into the chatlog
* @param username -> String, text -> String, group -> int
* @return None
*/
"""
func add_message(text:String,type:String,user_sent:String,from_user:String):
	var user = from_user
	var color:String = get_chat_color(type)
	if from_user == Save.game_data.username and type == "whisper":
		user = "To [ "+user_sent+" ]"
	chatLog.bbcode_text += "[color=" + color + "]"
	chatLog.bbcode_text += user + ': '
	chatLog.bbcode_text += text
	chatLog.bbcode_text += "[/color]"
	chatLog.bbcode_text += '\n'

"""
/*
* @pre called when player hits enter inside of textbox
* @post sends message to add_message function and clears textbox
* @param new_text -> String
* @return None
*/
"""
func _on_playerInput_text_entered(new_text):
	if new_text.length() > CHARACTER_LIMIT:
		text_overflow_warning()
	elif new_text != '':
		var arr_of_str:Array = separate_string(new_text+"\n") #separate string into array
		if "/whisper" == arr_of_str[0]:
			arr_of_str.pop_front() #pop /whisper
			var receiving_user = arr_of_str.pop_front() #get user to send to
			new_text = array_to_string(arr_of_str) #change new_text to edited message
			emit_signal("message_sent",new_text,true,receiving_user)
			if DEBUG_ON:
				add_message(new_text,"whisper",receiving_user,Save.game_data.username)
		else:
			emit_signal("message_sent",new_text,false,"")
			if DEBUG_ON:
				add_message(new_text,"general","everyone",Save.game_data.username)
		
	playerInput.text = ""

"""
/*
* @pre None
* @post separate a string into array based on spaces
* @param my_str -> String
* @return Array 
*/
"""
func separate_string(my_str:String) -> Array:
	var current: String = ""
	var result: Array = []
	for character in my_str:
		if character == " " or character == "\n":
			result.append(current)
			current = ""
		else:
			current += character
	return result

"""
/*
* @pre None
* @post convert and array of strings into a string separated by spaces
* @param arr_in -> Array
* @return String 
*/
"""
func array_to_string(arr_in:Array) -> String:
		var result = ""
		for i in range(0,arr_in.size()):
			result += arr_in[i] + " "
		return result

"""
/*
* @pre None
* @post return the color corresponding to what chat channel was passed in
* @param type -> String
* @return String 
*/
"""
func get_chat_color(type:String) -> String:
	if type == "general":
		return channel_colors['Green']
	elif type == "whisper":
		return channel_colors['Blue']
	else:
		return channel_colors['White']

"""
/*
* @pre Person submits message > CHARACTER_LIMIT
* @post places a popup on the screen saying too many characters
* @param None
* @return None 
*/
"""
func text_overflow_warning():
	var dialog = AcceptDialog.new()
	dialog.dialog_text = "Please keep messages <= 256 characters"
	dialog.window_title = "Message is too large"
	dialog.connect('modal_closed', dialog, 'queue_free')
	add_child(dialog)
	dialog.popup_centered()
