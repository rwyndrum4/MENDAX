extends Control


# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass


func _on_Start_pressed():
	# get_tree().current_scene.add_child(options)
	# get_tree().change_scene()
	pass 

func _on_Leaderboards_pressed():
	# var options = load("path to .tscn")
	# get_tree().current_scene.add_child(options)
	pass # Replace with function body.

func _on_Options_pressed():
	# var options = load("path to .tscn")
	# get_tree().current_scene.add_child(options)
	pass # Replace with function body.
	# My changes Demo


func _on_Quit_pressed():
	get_tree().quit()
	pass # Replace with function body.


func _on_Store_pressed():
	pass
