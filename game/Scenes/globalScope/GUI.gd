"""
* Programmer Name - Will Wyndrum
* Description - Layer for inventory to sit on, handles input to toggle open
* Date Created - 11/15/2022
* Date Revisions:
* Citations:
	Based on tutorial from https://www.youtube.com/watch?v=FHYb63ppHmk
"""

extends CanvasLayer

func _input(event):
	if event.is_action_pressed("inventory_toggle") and can_open_inv():
		$Inventory.visible = !$Inventory.visible
		$Inventory.initialize_inventory()

func can_open_inv() -> bool:
	var one = not $chatbox.in_chatbox
	var two = not $SettingsMenu.just_in_menu
	return one and two

# Called when the node enters the scene tree for the first time.
func _ready():
	$Inventory.visible = false
	pass # Replace with function body.
