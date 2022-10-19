extends Node


onready var itemfound=false;
func _ready():
	pass
		

func _on_item1area_body_entered(body:PhysicsBody2D)->void:
	if itemfound==false:
		$player/Label.show()




func _on_item1_body_entered(body:PhysicsBody2D)->void:
	
	$player/Label.hide()
	if itemfound==false:
		$player/Label2.show()
		$item1/Sprite.show()
		itemfound=true;



func _on_item1_body_exited(body:PhysicsBody2D)->void:
	$item1/Sprite.hide()
	$player/Label2.hide() # Replace with function body.



