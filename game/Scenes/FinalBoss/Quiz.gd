extends Control


onready var DisplayText=$VBoxContainer/DisplayText
onready var ListItem=$VBoxContainer/ItemList
onready var RestartButton=$VBoxContainer/Button
onready var maxdamage=0
onready var minhealth=0
onready var currentmin=0
onready var currentmax=0
var data=[
	{
		"number": 1,
		"question": "Which player inflicted the most damage?",
		"options": ["1", "2", "3","4"],
		"correctOptionIndex": 1
	},	
	{
		"number": 2,
		"question": "Which player had the lowest health after the second minigame?",
		"options": ["1", "2", "3","4"],
		"correctOptionIndex": 2
	},
	{
		"number": 3,
		"question": "Which player inflicted the most damage on the chandelier?",
		"options": ["1", "2", "3","4"],
		"correctOptionIndex": 1
	},	
	{
		"number": 4,
		"question": "Placeholder 4",
		"options": ["1", "2", "3","4"],
		"correctOptionIndex": 1
	},
	{
		"number": 5,
		"question": "Placeholder 5",
		"options": ["1", "2", "3","4"],
		"correctOptionIndex": 1
	}
]
	
var items : Array =data
var item : Dictionary
var index_item : int
var correct : float=0

# Called when the node enters the scene tree for the first time.
func _ready():
	refresh_scene() # Replace with function body.
	maxdmgdict()
	minhealthdict()
	for d in data:
		if d.get("number")==1:
			d["correctOptionIndex"]=maxdamage
		if d.get("number")==2:
			d["correctOptionIndex"]=minhealth

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
func maxdmgdict():
	currentmax=0
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
		
func refresh_scene():
	minhealthdict()
	maxdmgdict()
	if index_item>=items.size():
		show_result()
	else:
		show_question()
func show_result():
	ListItem.hide()
	RestartButton.show()
	var score=round(correct/items.size()*100)
	DisplayText.text="Your score is "+str(score)
func show_question():
	ListItem.show()
	RestartButton.hide()
	ListItem.clear()
	item=items[index_item]
	DisplayText.text=item.question
	var options=item.options
	for option in options:
		ListItem.add_item(option)
func read_json_file(filename):
	var file=File.new()
	file.open(filename,file.READ)
	var text=file.get_as_text()
	var json_data=parse_json(text)
	file.close()
	print(json_data)




func _on_ItemList_item_selected(index):
	print(item.question)
	print(item.correctOptionIndex)
	if index==item.correctOptionIndex:
		correct+=1
	index_item +=1
	refresh_scene() # Replace with function body.

func _on_Button_pressed():
	correct=0
	index_item=0
	refresh_scene() # Replace with function body.pass # Replace with function body.
