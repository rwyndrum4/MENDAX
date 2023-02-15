extends Node2D

var item_name
var item_quantity

func _ready():
	item_name = "Coin"
	var stack_size = int(INV.item_data[item_name]["StackSize"])
	
	item_quantity = (randi() % stack_size)
	
	if stack_size == 1:
		$Label.visible = false
	else:
		$Label.text = String(item_quantity)

func add_item_quantity(amount):
	item_quantity += amount
	$Label.text = String(item_quantity)

func sub_item_quantity(amount):
	item_quantity -= amount
	$Label.text = String(item_quantity)

func set_item(name, amount):
	item_name = name
	item_quantity = amount
	
	$TextureRect.texture = load("res://Assets/InventoryIcons/" + item_name + ".png")
	
	var stack_size = int(INV.item_data[item_name]["StackSize"])
	if stack_size == 1:
		$Label.visible = false
	else:
		$Label.visible = true
		$Label.text = String(item_quantity)
