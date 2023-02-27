extends Node2D

func _ready():
	pass


func _process(_delta):
	pass
	
	
func spawn():
	var imposter =preload("res://Scenes/Mobs/imposter.tscn")
	imposter.instance()
	


func _on_Timer_timeout():
	spawn()
