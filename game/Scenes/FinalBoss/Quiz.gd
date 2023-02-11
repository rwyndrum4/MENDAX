extends Control


onready var DisplayText=$VBoxContainer/DisplayText
onready var ListItem=$VBoxContainer/ItemList
onready var RestartButton=$VBoxContainer/Button
var data=[
	{
		"question": "Who inflicted the most damage?",
		"options": ["Ben", "Freeman", "Mohit"],
		"correctOptionIndex": 0
	},	
	{
		"question": "Placeholder 2",
		"options": ["1", "2", "3"],
		"correctOptionIndex": 2
	},
	{
		"question": "Placeholder 3",
		"options": ["1", "2", "3"],
		"correctOptionIndex": 0
	},	
	{
		"question": "Placeholder 4",
		"options": ["1", "2", "3"],
		"correctOptionIndex": 1
	},
	{
		"question": "Placeholder 5",
		"options": ["1", "2", "3"],
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
