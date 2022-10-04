extends KinematicBody2D

func _physics_process(_delta) -> void:
	var vel = Vector2(
		Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left"),
		Input.get_action_strength("ui_down") - Input.get_action_strength("ui_up")
	)
	vel *= 400
	# warning-ignore:return_value_discarded
	move_and_slide(vel)
