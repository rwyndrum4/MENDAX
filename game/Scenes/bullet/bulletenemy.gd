extends KinematicBody2D
var velocity=Vector2(1,1);
var speed=300;
var collision_info;
var id;

func set_id(num:int):
	id = num

func get_id() -> int:
	return id

func _physics_process(delta):
	collision_info = move_and_collide(velocity.normalized()*delta*speed)

func _on_Area2D2_body_entered(body):
	if body.is_in_group("wall"):
		queue_free()
	elif body.name == "Player":
		if not get_parent()._player_dead:
			queue_free()
			body.take_damage(10)
