"""
* Programmer Name - Ben Moeller
* Description - File for controlling the in game chatbox
* Date Created - 10/12/2022
* Date Revisions:
"""

extends Control

signal message_sent(msg,is_whisper,username)

# set to true if you want to test chatbox locally
var DEBUG_ON = false

# Member Variables
onready var chatLog = $textHolder/pastText
onready var playerInput = $textHolder/inputField/playerInput

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
	"White": "#ffffff",
	"Pink": "#f06eee",
	"Red": "#fa2a1b"
}
#Placeholder texts [aka everything for controlling autofill stuff]
var current_pt: int = 0
var current_usr: int = 0
var MAX_PT: int = 4
var placeholder_texts = [
	" SHIFT+ENTER to chat, Esc to exit",
	" Press TAB to cycle messages",
	" To send to everyone, input a message",
	" /whisper player_name message",
	" /clear to clear chatbox"
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
	$textHolder/pastText.scroll_following = true

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
		#If the user just entered the chat
		if event.pressed and Input.is_action_just_pressed("ui_enter_chat"):
			playerInput.grab_focus() #grab focus of chatbox
			in_chatbox = true
			modulate.a8 = MODULATE_MAX
			current_pt = 1
			playerInput.placeholder_text = placeholder_texts[current_pt]
			GlobalSignals.emit_signal("openChatbox",true)
		#If user leaves the chatbox
		if event.pressed and Input.is_action_just_pressed("ui_cancel"):
			playerInput.release_focus()
			in_chatbox = false
			modulate.a8 = MODULATE_MIN
			current_pt = 0
			playerInput.placeholder_text = placeholder_texts[current_pt]
			GlobalSignals.emit_signal("openChatbox",false)
		#If the user presses TAB
		if event.pressed and Input.is_action_just_pressed("ui_swap_chat_groups") and in_chatbox:
			if playerInput.text == "":
				current_pt += 1
				playerInput.placeholder_text = placeholder_texts[current_pt]
				if current_pt == MAX_PT:
					current_pt = 1
			else:
				#Auto fill for whisper
				if playerInput.text in "/whisper" and playerInput.text != "/":
					playerInput.text = "/whisper "
					playerInput.set_cursor_position(len(playerInput.text) +1)
				#Autofill for clear
				elif playerInput.text in "/clear" and playerInput.text != "/":
					playerInput.text = "/clear"
					playerInput.set_cursor_position(len(playerInput.text) +1)
				#Auto fill for current players
				elif "/whisper " in playerInput.text and ServerConnection.get_chatroom_players().size() > 0:
					playerInput.text = "/whisper " + ServerConnection.get_chatroom_players().keys()[current_usr] + " "
					playerInput.set_cursor_position(len(playerInput.text) +1)
					current_usr += 1
					if current_usr == ServerConnection.get_chatroom_players().size():
						current_usr = 0

"""
/*
* @pre called when user enters message into the chatbox
* @post formats text and puts it into the chatlog
* @param username -> String, text -> String, group -> int
* @return None
*/
"""
func add_message(text:String,type:String,user_sent:String,from_user:String):
	if "MATCH_RECEIVED " in text:
		#clean the string of match received
		var clean_data = text.replace("MATCH_RECEIVED ","")
		#get a dictionary from the string
		var match_dict:Dictionary = parse_json(clean_data)
		#add matches to current dictionary if not already in there
		for key in match_dict.keys():
			if not Global.match_exists(key):
				Global.add_match(key, match_dict[key])
		return
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
* @pre not connected to server, need to let user know can't send message
* @post Adds message to chatbox letting them know
* @param None
* @return None
*/
"""
func add_err_message():
	var color:String = get_chat_color("error")
	var err_msg = "[color=" + color + "]"
	err_msg += "Not connected to server, please wait[/color]"
	chatLog.bbcode_text += err_msg
	chatLog.bbcode_text += "\n"

"""
/*
* @pre something has happened with the chat
* @post adds chat message to let user know what happened with the chat
* @param event_message -> String (message to print)
* @return None
*/
"""
func chat_event_message(event_message: String):
	var color: String = get_chat_color("chat_event")
	var event_msg = "[color=" + color + "]"
	event_msg += event_message
	chatLog.bbcode_text += event_msg
	chatLog.bbcode_text += "\n"

"""
/*
* @pre called when player hits enter inside of textbox
* @post sends message to add_message function and clears textbox
* @param new_text -> String
* @return None
*/
"""
func _on_playerInput_text_entered(new_text):
	#Don't send message if user left message box then came back
	if Input.is_action_just_pressed("ui_enter_chat",false):
		return
	#If text length > 256 don't let them send it
	if new_text.length() > CHARACTER_LIMIT:
		text_overflow_warning()
	#If not sending an empty message
	elif new_text != '':
		var arr_of_str:Array = separate_string(new_text+"\n") #separate string into array
		#If the message is a whisper
		if "/whisper" == arr_of_str[0]:
			arr_of_str.pop_front() #pop /whisper
			var receiving_user = arr_of_str.pop_front() #get and pop user to send to
			new_text = array_to_string(arr_of_str) #change new_text to edited message
			emit_signal("message_sent",new_text,true,receiving_user)
			if DEBUG_ON:
				add_message(new_text,"whisper",receiving_user,Save.game_data.username)
		#If the user wants to clear the chatLog
		elif new_text == "/clear":
			chatLog.bbcode_text = ""
		#Else it is a message to send to general
		else:
			emit_signal("message_sent",new_text,false,"")
			if DEBUG_ON:
				add_message(new_text,"general","everyone",Save.game_data.username)
	#Reset the InputBox once message sent
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
	elif type == "error":
		return channel_colors['Red']
	elif type == "chat_event":
		return channel_colors['Pink']
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


func _on_playerInput_focus_entered():
	playerInput.grab_focus() #grab focus of chatbox
	in_chatbox = true
	modulate.a8 = MODULATE_MAX
	current_pt = 1
	playerInput.placeholder_text = placeholder_texts[current_pt]
	GlobalSignals.emit_signal("openChatbox",true)


func _on_playerInput_focus_exited():
	playerInput.release_focus()
	in_chatbox = false
	modulate.a8 = MODULATE_MIN
	current_pt = 0
	playerInput.placeholder_text = placeholder_texts[current_pt]
	GlobalSignals.emit_signal("openChatbox",false)
