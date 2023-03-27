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
		"question": "Which player inflicted the most damage?",
		"options": ["1", "2", "3","4"],
		"correctOptionIndex": 4
	},	
	{
		"number": 2,
		"question": "Which player had the lowest health after the second minigame?",
		"options": ["1", "2", "3","4"],
		"correctOptionIndex": 4
	},
	{
		"number": 3,
		"question": "Which player inflicted the most damage on the chandelier?",
		"options": ["1", "2", "3","4"],
		"correctOptionIndex": 2
	},	
	{
		"number": 4,
		"question": "Placeholder 4",
		"options": ["1", "2", "3","4"],
		"correctOptionIndex": 2
	},
	{
		"number": 5,
		"question": "Placeholder 5",
		"options": ["1", "2", "3","4"],
		"correctOptionIndex": 2
	}
]
	
var items : Array =data
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
	maxdmgdict()
	minhealthdict()
	
	#print(ListItem.rect_size)
	for d in data:
		if d.get("number")==1:
			d["correctOptionIndex"]=maxdamage-1
		if d.get("number")==2:
			d["correctOptionIndex"]=minhealth-1
	#index_item=0
	refresh_scene()
	

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
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
		
func refresh_scene():
	minhealthdict()
	maxdmgdict()
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
	print(item.question)
	print(item.correctOptionIndex)
	textBox.queue_text(str(item.question))
	textBox.display_text()

func read_json_file(filename):
	var file=File.new()
	file.open(filename,file.READ)
	var text=file.get_as_text()
	var json_data=parse_json(text)
	file.close()
	print(json_data)

func _on_Button1_pressed():
	$VBoxContainer/Button1.release_focus()
	index_item+=1
	if item.correctOptionIndex==0:
		correct+=1
		#print(str(index))
		print("correct")
	refresh_scene()

func _on_Button2_pressed():
	$VBoxContainer/Button2.release_focus()
	index_item+=1
	if item.correctOptionIndex==1:
		correct+=1
		print("correct")
	refresh_scene()


func _on_Button3_pressed():
	$VBoxContainer/Button3.release_focus()
	index_item+=1
	if item.correctOptionIndex==2:
		correct+=1
		print("correct")
	refresh_scene()


func _on_Button4_pressed():
	$VBoxContainer/Button4.release_focus()
	index_item+=1
	if item.correctOptionIndex==3:
		correct+=1
		print("correct")
	refresh_scene()
