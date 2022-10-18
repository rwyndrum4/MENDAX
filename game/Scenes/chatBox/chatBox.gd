extends Control

signal message_sent(msg)

# Member Variables
onready var chatLog = $textHolder/pastText
onready var playerName = $textHolder/inputField/playerName
onready var playerInput = $textHolder/inputField/playerInput

#The different types of chats
enum chat_types {
	GENERAL,
	WHISPER
}

#The color codes that correspond to the chat types
var types_colors = [
	{'name' : 'General', 'color' : '#51f538'},
	{'name' : 'Whisper', 'color' : '#9fd0fd'}
]

#Current chat type user is using
var current_type = chat_types.GENERAL
#Boolean that says if user is using chatbox
var in_chatbox = false
#Modulate values
var MODULATE_MIN = 140
var MODULATE_MAX = 255

"""
/*
* @pre called once to initialize scene
* @post Sets current chat type
* @param None
* @return None
*/
"""
func _ready():
	playerName.text = types_colors[current_type]['name']
	playerName.set('custom_colors/font_color', Color(types_colors[current_type]['color']))
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
			GlobalSignals.emit_signal("openChatbox",true)
		if event.pressed and Input.is_action_just_pressed("ui_cancel"):
			playerInput.release_focus()
			in_chatbox = false
			modulate.a8 = MODULATE_MIN
			GlobalSignals.emit_signal("openChatbox",false)
		if event.pressed and Input.is_action_just_pressed("ui_swap_chat_groups") and in_chatbox:
			change_group()

"""
/*
* @pre called in _input(event)
* @post Changes the current type of the chat group and chagnes color and name of text
* @param None
* @return None
*/
"""
func change_group():
	current_type += 1
	if current_type > chat_types.size() - 1:
		current_type = 0
	if current_type == chat_types.GENERAL:
		playerInput.placeholder_text = "SHIFT+ENTER to chat, Esc to exit"
	elif current_type == chat_types.WHISPER:
		playerInput.placeholder_text = "to:Player message"
	playerName.text = types_colors[current_type]['name']
	playerName.set('custom_colors/font_color', Color(types_colors[current_type]['color']))

"""
/*
* @pre called when user enters message into the chatbox
* @post formats text and puts it into the chatlog
* @param username -> String, text -> String, group -> int
* @return None
*/
"""
func add_message(username, text, group=0):
	if username == Global.chat_username:
		return
	chatLog.bbcode_text += '[color=' + types_colors[group]['color'] + ']'
	chatLog.bbcode_text += username + ': '
	chatLog.bbcode_text += text
	chatLog.bbcode_text += '[/color]'
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
	if new_text.length() > 40:
		var dialog = AcceptDialog.new()
		dialog.dialog_text = "Please keep messages <= 40 characters"
		dialog.window_title = "Message is too large"
		dialog.connect('modal_closed', dialog, 'queue_free')
		add_child(dialog)
		dialog.popup_centered()
	elif new_text != '':
		if current_type == chat_types.WHISPER:
			var arr_of_str:Array = separate_string(new_text+"\n") #separate string into array
			arr_of_str[0] = edit_whisper_str(arr_of_str[0]) #format who you're sending to
			new_text = array_to_string(arr_of_str) #change new_text to edited message
		add_message(Save.game_data.username,new_text, current_type)
		emit_signal("message_sent",new_text)
		
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
* @post make it so beginning of whisper string changes color to show who you sent whisper to
* @param my_str -> String
* @return String 
*/
"""
func edit_whisper_str(my_str:String) -> String:
	var result = "[color=#D2042D]("
	my_str = my_str.replace("to:","")
	result += my_str + ")"
	result += "[/color]"
	return result
