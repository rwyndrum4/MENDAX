extends Control

# Member Variables
onready var chatLog = $textHolder/pastText
onready var playerName = $textHolder/inputField/playerName
onready var playerInput = $textHolder/inputField/playerInput

enum chat_types {
	GENERAL,
	WHISPER
}

var types_colors = [
	{'name' : 'General', 'color' : '#51f538'},
	{'name' : 'Whisper', 'color' : '#9fd0fd'}
]

var current_type = chat_types.GENERAL


func _ready():
	playerName.text = types_colors[current_type]['name']
	playerName.set('custom_colors/font_color', Color(types_colors[current_type]['color']))

func _input(event):
	if event is InputEventKey:
		if event.pressed and Input.is_action_just_pressed("ui_accept"):
			playerInput.grab_focus()
		if event.pressed and Input.is_action_just_pressed("ui_cancel"):
			playerInput.release_focus()
		if event.pressed and Input.is_action_just_pressed("ui_focus_next"):
			change_group()

func change_group():
	current_type += 1
	if current_type > chat_types.size() - 1:
		current_type = 0
	playerName.text = types_colors[current_type]['name']
	playerName.set('custom_colors/font_color', Color(types_colors[current_type]['color']))

func add_message(username, text, group=0):
	chatLog.bbcode_text += '[color=' + types_colors[group]['color'] + ']'
	chatLog.bbcode_text += '[' + username + ']: '
	chatLog.bbcode_text += text
	chatLog.bbcode_text += '[/color]'
	chatLog.bbcode_text += '\n'

func _on_playerInput_text_entered(new_text):
	if new_text != '':
		add_message("test",new_text, current_type)
		playerInput.text = ''
