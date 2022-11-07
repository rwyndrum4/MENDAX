"""
* Programmer Name - Will Wyndrum
* Description - Node for slots within the inventory
* Date Created - 10/10/2022
* Date Revisions:
* Citations:
	Based on tutorial from https://www.youtube.com/watch?v=FHYb63ppHmk
"""

extends Node2D

const SlotClass = preload("res://Inventory/Slot.gd")
onready var inventory_slots = $GridContainer
var holding_item = null

# Called when the node enters the scene tree for the first time.
func _ready():
	for inv_slot in inventory_slots.get_children():
		inv_slot.connect("gui_input", self, "slot_gui_input", [inv_slot])
	initialize_inventory()

func initialize_inventory():
	var slots = inventory_slots.get_children()
	for i in range(slots.size()):
		if PlayerInventory.inventory.has(i):
			slots[i].initialize_item(PlayerInventory.inventory[i][0], PlayerInventory.inventory[i])


func slot_gui_input(event: InputEvent, slot: SlotClass):
	if event is InputEventMouseButton:
		if event.button_index == BUTTON_LEFT && event.pressed:
			if holding_item != null:
				if slot.item == null: # place into slot
					slot.putIntoSlot(holding_item)
					holding_item = null
				else: # swap holding item with item in slot
					if holding_item.item_name != slot.item.item_name:
						var temp_item = slot.item
						slot.pickFromSlot()
						temp_item.global_position = event.global_position
						slot.putIntoSlot(holding_item)
						holding_item = temp_item
					else:
						var stack_size = int(INV.item_data[slot.item.item_name]["StackSize"])
						var abletoadd = stack_size - slot.item.item_quantity
						if abletoadd >= holding_item.item_quantity:
							PlayerInventory.add_item_quantity(slot, holding_item.item_quantity)
							slot.item.add_item_quantity(holding_item.item_quantity)
							holding_item.queue_free()
							holding_item = null
						else:
							PlayerInventory.add_item_quantity(slot, abletoadd)
							slot.item.add_item_quantity(abletoadd)
							holding_item.sub_item_quantity(abletoadd)
			elif slot.item:
				holding_item = slot.item
				slot.pickFromSlot()
				holding_item.global_position = get_global_mouse_position()

func _input(event):
	if holding_item:
		holding_item.global_position = get_global_mouse_position()
		
