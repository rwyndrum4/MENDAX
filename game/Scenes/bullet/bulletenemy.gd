extends KinematicBody2D
var velocity=Vector2(0,0);
var speed=300;

# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
func _physics_process(delta):
	var collision_info= move_and_collide(velocity.normalized()*delta*speed)



func _on_Area2D_body_entered(body):
	if "Player" in body.name:
		queue_free() 
		pass # Replace with function body.
