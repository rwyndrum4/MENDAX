extends Control


onready var DisplayText=$VBoxContainer/DisplayText
onready var ListItem=$VBoxContainer/ItemList
onready var RestartButton=$VBoxContainer/Button
var data=[
	{
		"question": "If you freeze water, what do you get?",
		"options": ["Ice", "Bomb", "Fire"],
		"correctOptionIndex": 0
	},	
	{
		"question": "What's the name of a place you go to see lots of animals?",
		"options": ["Airport", "School", "Zoo"],
		"correctOptionIndex": 2
	},
	{
		"question": "What do caterpillars turn into?",
		"options": ["Butterflies", "Fish", "Birds"],
		"correctOptionIndex": 0
	},	
	{
		"question": "On which holiday do you go trick-or-treating?",
		"options": ["Christmas", "Halloween", "Easter"],
		"correctOptionIndex": 1
	},
	{
		"question": "Which is the fastest land animal?",
		"options": ["Turtle", "Cheetah", "Snail"],
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


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
func refresh_scene():
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
	if index==item.correctOptionIndex:
		correct+=1
	index_item +=1
	refresh_scene() # Replace with function body.

func _on_Button_pressed():
	correct=0
	index_item=0
	refresh_scene() # Replace with function body.pass # Replace with function body.
