extends Area2D



func _ready():
	self.hide()

func _on_item1_body_entered(body:PhysicsBody2D)->void:
	print("Hello") # Replace with function body.
