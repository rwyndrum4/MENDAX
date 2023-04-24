"""
* Programmer Name - Freeman Spray
* Description - Aesthetic-controlling code for a torch equippable
* Date Created - 1/29/2023
			
"""
extends Light2D

#objects
onready var timer = $Timer
onready var light = get_parent()

var _ticks = 0
var _mode = "burn"
var _drops = 0
var burning = true

# Called when the node enters the scene tree for the first time.
func _ready():
	timer.start(120)
	toggle_burning()
	visible = true
	light.visible = true

func toggle_burning():
	timer.set_paused(!visible)
	light.visible = !light.visible
	visible = !visible

"""
Use to refresh torch, dont instance new
"""
func replenish_torch():
	timer.set_wait_time(120)
	
"""
/*
* @pre Called every frame
* @param None
* @return None
*/
"""
func _process(_delta):
	if visible:
		set("texture_scale",((timer.get_time_left()/120)*100))
		set("energy", 1)
	else:
		set("energy", 0)
