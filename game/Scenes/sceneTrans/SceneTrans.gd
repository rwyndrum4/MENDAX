"""
* Programmer Name - Jason Truong
* Description - This file is a scene transition animation that adds a fade to black animation to the target scene. 
* Date Created - 9/16/2022
* Date Revisions:
	9/17/2022 - Added options menu functionality
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
func change_scene(target: String) -> void:
	$AnimationPlayer.play("DISSOLVE")
	yield($AnimationPlayer, 'animation_finished')
	# warning-ignore:return_value_discarded
	get_tree().change_scene(target)
	$AnimationPlayer.play_backwards("DISSOLVE")
	
