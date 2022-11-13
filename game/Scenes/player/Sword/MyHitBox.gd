class_name MyHitBox

extends Area2D

export var damage := 10

func _init() -> void:
	collision_layer = 19
	collision_mask = 0
