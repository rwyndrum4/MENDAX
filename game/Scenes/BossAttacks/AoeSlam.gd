extends Area2D

onready var drawing = $anim_drawing
var _speed = Vector2(0.01,0.01)
var _got_too_big:bool = false
signal aoe_attack_hit()

func _ready():
	scale = Vector2(2,2)
	drawing.play("default")
	$bwam.play()
	$swoosh.playing = true

func _process(_delta):
	scale += _speed
	_speed.x += 0.0008
	_speed.y += 0.0008
	if scale > Vector2(150,150):
		modulate.a8 -= 1
	if Vector2(200,200) < scale:
		_got_too_big = true
		emit_signal("aoe_attack_hit")

func _on_AoEAttack_area_entered(area):
	if not _got_too_big and area.is_in_group("player"):
		get_parent().player.take_damage(5)
		emit_signal("aoe_attack_hit")
