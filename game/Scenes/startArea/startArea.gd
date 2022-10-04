extends Control


# Member Variables:
var in_cave = false
onready var instructions: Label = $enterDirections


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


func _process(delta):
	if in_cave:
		if Input.is_action_just_pressed("ui_accept",false):
			get_tree().change_scene("res://Scenes/startArea/EntrySpace.tscn")


func _on_Area2D_body_entered(body: PhysicsBody2D):
	instructions.show()
	in_cave = true


func _on_Area2D_body_exited(body: PhysicsBody2D):
	in_cave = false
	instructions.hide()
