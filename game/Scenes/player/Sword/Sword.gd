extends Node
var direction

	
	
func _process(delta):
	if Input.is_action_just_pressed("mouse_click_left", false):
		if direction == "right":
			$AnimationPlayer.play("slash")
			yield($AnimationPlayer, 'animation_finished')
			$AnimationPlayer.play("slash_rev")
			yield($AnimationPlayer, 'animation_finished')
		else:
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


