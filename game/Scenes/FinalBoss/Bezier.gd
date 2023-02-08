extends StaticBody2D

var _in_radius = 0


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

func _input(_ev):
	if _in_radius:
		if Input.is_action_just_pressed("ui_accept",false) and not Input.is_action_just_pressed("ui_enter_chat"):
			$Light2D.show()
			$TileTexture.set("texture", "res://Assets/tiles/TilesCorrected/BezierLit.png")
