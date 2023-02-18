extends Area2D

var _speed = Vector2(0.01,0.01)

func _process(_delta):
	scale += _speed
	_speed.x += 0.0001
	_speed.y += 0.0001

func _on_AoEAttack_area_entered(_area):
	print("here")
