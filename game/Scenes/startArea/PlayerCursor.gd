extends KinematicBody2D

const ACCELERATION = 25000
const MAX_SPEED = 500
const FRICTION = 500

var velocity = Vector2.ZERO

# Reference: https://www.youtube.com/watch?v=TQKXU7iSWUU
func _physics_process(delta):
	var input_velocity = Vector2.ZERO
	input_velocity.x = Input.get_axis("ui_left", "ui_right")
	input_velocity.y = Input.get_axis("ui_up", "ui_down") 
	input_velocity = input_velocity.normalized()
	
	if input_velocity == Vector2.ZERO:
		velocity = input_velocity.move_toward(Vector2.ZERO, FRICTION*delta)
	elif input_velocity.x == 0:
		velocity = input_velocity.move_toward(Vector2(0,input_velocity.y).normalized()*MAX_SPEED, ACCELERATION*delta)
	elif input_velocity.y == 0:
		velocity = input_velocity.move_toward(Vector2(input_velocity.x,0).normalized()*MAX_SPEED, ACCELERATION*delta)
	else:
		velocity = input_velocity.move_toward(0.7*input_velocity*MAX_SPEED, ACCELERATION*delta)
	
	velocity = move_and_slide(velocity)
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
