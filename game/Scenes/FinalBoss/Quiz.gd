extends Control


onready var DisplayText=$VBoxContainer/DisplayText
#onready var ListItem=$VBoxContainer/ItemList

onready var maxdamage=0
onready var minhealth=0
onready var currentmin=0
onready var currentmax=0
onready var textBox = $textBox
var data=[
	{
		"number": 1,
		"question": "Which player inflicted the most damage in the Arena?",
		"correctOptionIndexes": []
	},	
	{
		"number": 2,
		"question": "Which player had the lowest health in the Arena?",
		"correctOptionIndexes": []
	},
	{
		"number": 3,
		"question": "Which player inflicted the most damage on the chandeliers in the Arena?",
		"correctOptionIndexes": []
	},	
	{
		"number": 4,
		"question": "Which player hit the most good notes in the rhythm game?",
		"correctOptionIndexes": []
	}
]
	
var items : Array = data
var item : Dictionary
var index_item : int
var correct : float=0


"""
/*
* @pre enter quiz scene
* @post sets correct answers for quiz
* @param None
* @return None
*/
"""
# Called when the node enters the scene tree for the first time.
func _ready():
	# Replace with function body.
	if ServerConnection.match_exists() and ServerConnection.get_server_status():
		change_buttons_to_players()
	else:
		no_quiz_needed()
		return
	maxdmgdict()
	minhealthdict()
	for d in data:
		if d.get("number")==1:
			d["correctOptionIndexes"].append(maxdamage-1)
		if d.get("number")==2:
			d["correctOptionIndexes"].append(minhealth-1)
		if d.get("number")==3:
			var chand_vals = Global.chandelier_damage.values()
			d["correctOptionIndexes"] = get_winners(chand_vals)
		if d.get("number")==4:
			var goods = Global.player_good_notes.values()
			d["correctOptionIndexes"] = get_winners(goods)
	refresh_scene()

func maxdmgdict():
	currentmax=-1
	#maxdamage=2
	for i in 4:
		if (Global.bod_damage[str(i+1)]+Global.skeleton_damage[str(i+1)]+Global.chandelier_damage[str(i+1)]>currentmax):
			maxdamage=i+1
			currentmax=Global.bod_damage[str(i+1)]+Global.skeleton_damage[str(i+1)]+Global.chandelier_damage[str(i+1)]
		
func minhealthdict():
	currentmin=1000
	#minhealth=2
	for i in 4:
		if(Global.player_health[str(i+1)]<currentmin):
			currentmin=Global.player_health[str(i+1)]
			minhealth=i+1

func get_winners(scores:Array) -> Array:
	var maxVal = 0
	var result = []
	var inc = 0
	for value in scores:
		if value >= maxVal:
			maxVal = value
			result.append(inc)
		inc += 1
	return result

func refresh_scene():
	if index_item>=items.size():
		show_result()
	else:
		show_question()

func show_result():
	#ListItem.hide()
	#var score=round(correct/items.size()*100)
	#DisplayText.text="Your score is "+str(score)
	Global.progress = 7
	Global.state = Global.scenes.CAVE

func show_question():
	item=items[index_item]
	textBox.queue_text(str(item.question))
	textBox.display_text()

func read_json_file(filename):
	var file=File.new()
	file.open(filename,file.READ)
	var text=file.get_as_text()
	var json_data=parse_json(text)
	file.close()
	print(json_data)

func change_buttons_to_players():
	var names: Array = Global.player_names.values()
	var p_count = len(names)
	for i in range(4):
		if (i+1) > p_count:
			turn_off_button(i)
		else:
			change_button_text(names[i],i)

func change_button_text(bText:String, id:int):
	match id:
		0: $VBoxContainer/Button1.text = bText
		1: $VBoxContainer/Button2.text = bText
		2: $VBoxContainer/Button3.text = bText
		3: $VBoxContainer/Button4.text = bText

func turn_off_button(id:int):
	match id:
		0: $VBoxContainer/Button1.hide()
		1: $VBoxContainer/Button2.hide()
		2: $VBoxContainer/Button3.hide()
		3: $VBoxContainer/Button4.hide()

func _on_Button1_pressed():
	$VBoxContainer/Button1.release_focus()
	index_item+=1
	if 0 in item.correctOptionIndexes:
		correct+=1
		#print(str(index))
		print("correct")
	refresh_scene()

func _on_Button2_pressed():
	$VBoxContainer/Button2.release_focus()
	index_item+=1
	if 1 in item.correctOptionIndexes:
		correct+=1
		print("correct")
	refresh_scene()


func _on_Button3_pressed():
	$VBoxContainer/Button3.release_focus()
	index_item+=1
	if 2 in item.correctOptionIndexes:
		correct+=1
		print("correct")
	refresh_scene()


func _on_Button4_pressed():
	$VBoxContainer/Button4.release_focus()
	index_item+=1
	if 3 in item.correctOptionIndexes:
		correct+=1
		print("correct")
	refresh_scene()

func no_quiz_needed():
	$VBoxContainer/Button1.hide()
	$VBoxContainer/Button2.hide()
	$VBoxContainer/Button3.hide()
	$VBoxContainer/Button4.hide()
	# warning-ignore:return_value_discarded
	GlobalSignals.connect("textbox_empty", self, "show_result")
	textBox.queue_text("You are playing solo, no quiz needed")
	textBox.queue_text("Good luck with the last phase of the boss")
	textBox.queue_text("You may need it ^_^")
