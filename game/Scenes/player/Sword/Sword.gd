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
* @pre Called once when spawned
* @post Adds its area2d to the sword group
* @param None
* @return None
*/
"""
func _ready():
	$pivot/Sprite/MyHitBox.add_to_group("sword")
	GlobalSignals.connect("reach",self,"reach_up")

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
			
			if $pivot/Sprite/swing.playing == false:
				$pivot/Sprite/swing.play()
			$AnimationPlayer.play("slash")
			yield($AnimationPlayer, 'animation_finished')
			$AnimationPlayer.play("slash_rev")
			yield($AnimationPlayer, 'animation_finished')
		else:
			if $pivot/Sprite/swing.playing == false:
				$pivot/Sprite/swing.play()
			ServerConnection.send_arena_sword("left")
			$AnimationPlayer.play("slashLeft")
			yield($AnimationPlayer, 'animation_finished')
	
	if Input.is_action_just_pressed("ui_left", false):
		$AnimationPlayer.play("RESET2")
		yield($AnimationPlayer, 'animation_finished')
		$pivot.scale.x = -1

		direction = "left"

	if Input.is_action_just_pressed("ui_right", false):
		$AnimationPlayer.play("RESET")
		yield($AnimationPlayer, 'animation_finished')
		$pivot.scale.x = 1
		
		direction = "right"
		
"""
* @pre Catches "reach" signal
* @post activates or deactivates effect of "reach" powerup
* @param state -> indicates whether the function should activate or deactivate
"""		
func reach_up(state):
	if state == "deactivate":
		$pivot/Sprite/MyHitBox/CollisionShape2D.scale = $pivot/Sprite/MyHitBox/CollisionShape2D.scale/4
	elif state == "activate":
		$pivot/Sprite/MyHitBox/CollisionShape2D.scale = $pivot/Sprite/MyHitBox/CollisionShape2D.scale*4
