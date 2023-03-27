"""
* Programmer Name - Mohit Garg, Jason Truong
* Description - Code that designates mob animations
* Date Created - 3/12/2022
* Date Revisions:
	3/25/2023 - New animations and changed move_and_collide to move_and_slide
"""
extends KinematicBody2D
var velocity=Vector2(1,1);
var speed=300;
var collision_info = Vector2.ZERO;
var id;

onready var pos = $Position2D
func set_id(num:int):
	id = num

func get_id() -> int:
	return id

func _physics_process(_delta):
	collision_info = move_and_slide(velocity*speed)
	control_anim(collision_info)

func _on_Area2D2_body_entered(body):
	if body.is_in_group("wall"):
		queue_free()
	elif body.name == "Player":
		if not get_parent()._player_dead:
			queue_free()
			body.take_damage(10)
			
func control_anim(vel:Vector2):
	#Bullet moves East
	if vel.x > 0:
		pos.rotation_degrees = 90
		pos.scale.y = -1
		
	#Bullet moves West
	elif vel.x < 0:
		pos.rotation_degrees = 90
		pos.scale.y = -1
	#Bullet moves North
	elif vel.y < 0:
		pos.scale.y = 1
	#Bullet moves South
	elif vel.y > 0:
		pos.scale.y = -1

	else:
		pass
