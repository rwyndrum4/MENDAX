extends Node2D

@onready var hotbar = $HotbarSlots
@onready var slots = hotbar.get_children()

func _ready():
	for i in range(slots.size()):
		slots[i].slot_index = i
	initialize_hotbar()

func initialize_hotbar():
	for i in range(slots.size()):
		if PlayerInventory.hotbar.has(i):
			slots[i].initialize_item(PlayerInventory.hotbar[i][0], PlayerInventory.hotbar[i][1])
