extends CharacterBody2D
var velocity=Vector2(1,1);
var speed=300;
var collision_info;

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
	collision_info= move_and_collide(velocity.normalized()*delta*speed)

func _on_Area2D2_body_entered(body):
	if  !"chandelier" in body.name and not "BoD" in body.name and not "skeleton" in body.name and not "StaticBody2D" in body.name:
		queue_free() 
	if "Player" in body.name:
		
		var Player = get_parent().get_node("Player")
		
		#enter health bar stuff here
		Player.take_damage(10)
		print("player got shot 10 dmg")
