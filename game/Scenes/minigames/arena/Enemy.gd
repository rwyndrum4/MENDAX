extends KinematicBody2D

#motion vector for enemy
var motion=Vector2()
var timer=0;

# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.
"""
pre 
"""
func _physics_process(delta):
	##position +=(Player.position-position)/50 #enemy moves toward player
	var Player=get_parent().get_node("Player")
	position=Vector2(500,500)
	look_at(Player.position)
	move_and_collide(motion)
	timer+=delta
	print(timer)
	if timer>3:
		fire();
		timer=0;
		


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
var bullete =preload("res://Scenes/bullet/bulletenemy.tscn")
func fire():
	var Player=get_parent().get_node("Player")
	var bulenemy = bullete.instance()
	#get_tree().get_root().add_child(bulenemy)
	get_parent().add_child(bulenemy)
	bulenemy.global_position = global_position
	bulenemy.velocity=Player.position-bulenemy.position
"""
pre 
"""




func _on_Area2D_body_entered(body):
	#if "bulletplayer" in body.name:
		#print ("jello")
		#queue_free() 
	pass # Replace with function body.
