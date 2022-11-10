extends Node

const NUM_INVENTORY_SLOTS = 20

var inventory = {
}

func add_item(name, amount):
	for item in inventory:
		if inventory[item][0] == name:
			#TODO check if slot is full
			inventory[item][1] =+ amount
			return
	for i in range(NUM_INVENTORY_SLOTS):
		if inventory.has(i) == false:
			inventory[i] = [name, amount]
			return
		
