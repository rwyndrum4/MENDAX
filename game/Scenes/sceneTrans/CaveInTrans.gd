"""
* Programmer Name - Jason Truong
* Description - This file is a scene transition animation that adds a cave transition animation to the target scene. 
* Date Created - 10/1/2022
* Date Revisions:
	N/A
"""
extends CanvasLayer

"""
/*
* @pre None
* @post Goes to the target scene
* @param String of the scene being transitioned to
* @return None
*/
"""
#Fade to black transition
func change_scene(target) -> void:
	$AnimationPlayer.play("DISSOLVE")
	yield($AnimationPlayer, 'animation_finished')
	$AnimationPlayer.play("ENTERCAVE")
	yield($AnimationPlayer, 'animation_finished')
	$Exit.play()
	# warning-ignore:return_value_discarded
	Global.state = target
	$AnimationPlayer.play("EXITCAVE")
	
