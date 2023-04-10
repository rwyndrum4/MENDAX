"""
* Programmer Name - Jason Truong
* Description - This file is a scene transition animation that for intro scene. 
* Date Created - 3/11/2023
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
func change_scene(target) -> void:
	$AnimationPlayer.play("RESET")
	$AnimationPlayer.play("BUSH")
	yield($AnimationPlayer, 'animation_finished')
	$AnimationPlayer.play("SLIMES_ROLLOUT_P1")
	yield($AnimationPlayer, 'animation_finished')
	# warning-ignore:return_value_discarded
	Global.state = target
	$AnimationPlayer.play("SLIMES_ROLLOUT_P2")
	yield($AnimationPlayer, 'animation_finished')
	$AnimationPlayer.play_backwards("BUSH")
