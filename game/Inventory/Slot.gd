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
var highlighted_tex = preload("res://Assets/2D Casual GUI/Usable/highlighted_tile.png")

var default_style: StyleBoxTexture = null
var highlighted_style: StyleBoxTexture = null

var item = null
var ItemClass = preload("res://Inventory/Item.tscn")
var slot_index

enum SlotType {
	HOTBAR = 0,
	INVENTORY,
	SHIRT,
	PANTS,
	SHOES,
}

var slotType = null

func refresh_style(): # useful for having a new empty inventory slot icon
	if slotType == SlotType.HOTBAR and PlayerInventory.active_item_slot == slot_index:
		set('custom_styles/panel', highlighted_style)
	else:
		set('custom_styles/panel', default_style)

# Called when the node enters the scene tree for the first time.
func _ready():
	default_style = StyleBoxTexture.new()
	highlighted_style = StyleBoxTexture.new()
	default_style.texture = default_tex
	highlighted_style.texture = highlighted_tex
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
