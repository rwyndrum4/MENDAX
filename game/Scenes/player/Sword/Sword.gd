"""
* Programmer Name - Jason Truong
* Description - Code for player's sword
* Date Created - 11/20/2022
			
"""
extends Node
var direction

	
"""
/*
* @pre Called for every frame
* @post Does actions according to inputs detected
* @param _delta -> time variable that can be optionally used
* @return None
*/
"""
func _process(_delta):
	if Input.is_action_just_pressed("mouse_click_left", false):
		if direction == "right":
			ServerConnection.send_arena_sword("right")
			$AnimationPlayer.play("slash")
			yield($AnimationPlayer, 'animation_finished')
			$AnimationPlayer.play("slash_rev")
			yield($AnimationPlayer, 'animation_finished')
		else:
			ServerConnection.send_arena_sword("left")
			$AnimationPlayer.play("slashLeft")
			yield($AnimationPlayer, 'animation_finished')
	
	if Input.is_action_just_pressed("ui_left", false):
		$AnimationPlayer.play("RESET2")
		$pivot.scale.x = -1
		
		direction = "left"
		
	if Input.is_action_just_pressed("ui_right", false):
		$AnimationPlayer.play("RESET")
		$pivot.scale.x = 1
		
		direction = "right"


