"""
* Programmer Name - Freeman Spray
* Description - Code for animating the players' escape from the cave
* Date Created - 3/11/2023
* Date Revisions:
"""
extends Control



# Called when the node enters the scene tree for the first time.
func _ready():
	pass


# Called every frame. 'delta' is the elapsed time since the previous frame (remove the '_' if you want to use).
func _process(_delta):
	if($PlayerSprite.position.y < 800):
		$PlayerSprite.position.x = $PlayerSprite.position.x * 1.004
		$PlayerSprite.position.y = $PlayerSprite.position.y * 1.0025
		$PlayerSprite.scale = $PlayerSprite.scale * 1.0035
	
