extends Area2D


onready var itemarea=get_parent().hititem


func _on_item1_body_entered(body:PhysicsBody2D)->void:
	itemarea=true;
	print("Yes")
