extends KinematicBody2D

func _physics_process(delta) -> void:
	var vel = Vector2(
		Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left"),
		Input.get_action_strength("ui_down") - Input.get_action_strength("ui_up")
	)
	vel *= 400
	move_and_slide(vel)
