"""
* Programmer Name - Freeman Spray
* Description - Aesthetic-controlling code for a torch equippable
* Date Created - 1/29/2023
			
"""
extends Light2D


var _ticks = 0
var _mode = "burn"
var _drops = 0


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


"""
/*
* @pre Called every frame
* @post Adjust light level of torch every 200 ticks. Disappear torch animation and last trace of light once peak reduction is met
* @param None
* @return None
*/
"""
func _process(_delta):
	var tex_scale = get("texture_scale")
	if tex_scale > 0.1:
		set("texture_scale", tex_scale - 0.0025)
	else:
		set("energy", 0)
		get_parent().hide()
