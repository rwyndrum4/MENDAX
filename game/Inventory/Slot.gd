"""
* Programmer Name - Will Wyndrum
* Description - Node for slots within the inventory
* Date Created - 10/10/2022
* Date Revisions:
* Citations:
	Based on tutorial from https://www.youtube.com/watch?v=FHYb63ppHmk
"""
extends Panel

var ItemClass = preload("res://Inventory/Item.tscn")
var item = null

# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
	item = ItemClass.instance()
	add_child(item)


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
