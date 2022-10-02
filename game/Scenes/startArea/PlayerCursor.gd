extends KinematicBody2D

const ACCELERATION = 30000
const MAX_SPEED = 800
const FRICTION = 500

var velocity = Vector2.ZERO

# Reference: https://www.youtube.com/watch?v=TQKXU7iSWUU
func _physics_process(delta):
	velocity = Vector2.ZERO
	velocity.x = Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left")
	velocity.y = Input.get_action_strength("ui_down") - Input.get_action_strength("ui_up") 
	velocity = velocity.normalized()
	
	if velocity != Vector2.ZERO:
		velocity = velocity.move_toward(velocity*MAX_SPEED, ACCELERATION*delta)
	else:
		velocity = velocity.move_toward(Vector2.ZERO, FRICTION*delta)
	
	velocity = move_and_collide(velocity*delta)
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
