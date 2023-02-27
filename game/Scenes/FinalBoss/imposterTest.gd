extends Node2D
var imposter =preload("res://Scenes/Mobs/imposter.tscn")
onready var player = $Player
onready var confuzzed = $Player/confuzzle

func _process(delta):
	if player.isInverted == true:
		confuzzed.visible = true
	else:
		confuzzed.visible = false
		
func spawn():
	var new_imposter = imposter.instance()
	new_imposter.position = Vector2(750, 1200)
	add_child(new_imposter)
	


func _on_Timer_timeout():
	spawn()
