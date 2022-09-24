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
	get_tree().change_scene(target)
	$AnimationPlayer.play_backwards("DISSOLVE")
	
