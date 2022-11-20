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
	var Player=get_parent().get_node("Player")
	position +=(Player.position-position)/50 #enemy moves toward player
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
var bullet = preload("res://Scenes/bullet/bullet.tscn")
func fire():
	var bul = bullet.instance()
	get_tree().get_root().add_child(bul)
	bul.global_position = global_position
"""
pre 
"""
func _on_Area2D_body_entered(body):
	if "bullet" in body.name:
		print ("hello")
		##queue_free() 
