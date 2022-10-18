extends Area2D

#onready var itemnode = get_node("item1")
onready var textBox = $GUI/textBox
onready var hititem=false;
func _ready():
	pass
	#self.hide()
	#textBox.queue_text("You are close to the item")

func _on_item1_body_entered(body:PhysicsBody2D)->void:
	if hititem==false:
		print("hello")# Replace with function body.
