"""
* Programmer Name - Jason Truong
* Description - Code for player's sword
* Date Created - 11/20/2022
*Date Revisions: 1/29/2023 - Added sword swing

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
	if Input.is_action_just_pressed("mouse_click_left", false) or Input.is_action_just_pressed("jump", false):
		if direction == "right":
			ServerConnection.send_arena_sword("right")
			
			if $pivot/Sprite2D/swing.playing == false:
				$pivot/Sprite2D/swing.play()
			$AnimationPlayer.play("slash")
			await $AnimationPlayer.animation_finished
			$AnimationPlayer.play("slash_rev")
			await $AnimationPlayer.animation_finished
		else:
			if $pivot/Sprite2D/swing.playing == false:
				$pivot/Sprite2D/swing.play()
			ServerConnection.send_arena_sword("left")
			$AnimationPlayer.play("slashLeft")
			await $AnimationPlayer.animation_finished
	
	if Input.is_action_just_pressed("ui_left", false):
		$AnimationPlayer.play("RESET2")
		await $AnimationPlayer.animation_finished
		$pivot.scale.x = -1

		direction = "left"

	if Input.is_action_just_pressed("ui_right", false):
		$AnimationPlayer.play("RESET")
		await $AnimationPlayer.animation_finished
		$pivot.scale.x = 1
		
		direction = "right"
