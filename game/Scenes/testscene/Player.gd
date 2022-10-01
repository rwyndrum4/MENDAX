extends KinematicBody2D


# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
var velocity=Vector2.ZERO
func _physics_process(delta):
	var input_vector=Vector2.ZERO
	input_vector.x =Input.get_action_strength("ui_right")-Input.get_action_strength("ui_left")
	input_vector.y=Input.get_action_strength("ui_down")-Input.get_action_strength("ui_up")
	
	if input_vector != Vector2.ZERO:
		velocity=input_vector
	else:
		velocity = Vector2.ZERO
	move_and_collide(velocity)

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass

