extends Area2D

onready var drawing = $anim_drawing
var _speed = Vector2(0.01,0.01)
signal aoe_attack_hit()

func _ready():
	drawing.play("default")

func _process(_delta):
	scale += _speed
	_speed.x += 0.0001
	_speed.y += 0.0001

func _on_AoEAttack_area_entered(_area):
	emit_signal("aoe_attack_hit")
