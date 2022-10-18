extends Node

#onready var itemarea=false;
# Declare member variables here. Examples:
# var a = 2
# var b = "text"
# Called when the node enters the scene tree for the first time.
func _ready():
	pass
		

func _on_item1area_body_entered(body:PhysicsBody2D)->void:
	$player/Label.show()





func _on_item1_body_entered(body):
	$player/Label.hide()
	$player/Label2.show()
