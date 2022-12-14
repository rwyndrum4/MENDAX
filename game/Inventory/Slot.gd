"""
* Programmer Name - Will Wyndrum
* Description - Node for slots within the inventory
* Date Created - 10/10/2022
* Date Revisions:
* Citations:
	Based on tutorial from https://www.youtube.com/watch?v=FHYb63ppHmk
"""
extends Panel

var default_tex = preload("res://Assets/2D Casual GUI/Usable/menu_tile.png")
var empty_tex = null

var default_style: StyleBoxTexture = null
var empty_style: StyleBoxTexture = null

var item = null
var ItemClass = preload("res://Inventory/Item.tscn")
var slot_index

func refresh_style(): # useful for having a new empty inventory slot icon
	pass

# Called when the node enters the scene tree for the first time.
func _ready():
	default_style = StyleBoxTexture.new()
	empty_style = StyleBoxTexture.new()
	refresh_style()


func pickFromSlot():
	remove_child(item)
	var inventoryNode = find_parent("Inventory")
	inventoryNode.add_child(item)
	item = null
	refresh_style()

func putIntoSlot(new_item):
	item = new_item
	item.position = Vector2(0, 0)
	var inventoryNode = find_parent("Inventory")
	inventoryNode.remove_child(item)
	add_child(item)
	refresh_style()	

func initialize_item(name, amount):
	if item == null:
		item = ItemClass.instance()
		add_child(item)
		item.set_item(name, amount)
	else:
		item.set_item(name, amount)
	refresh_style()
