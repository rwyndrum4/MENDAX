extends Area2D

onready var drawing = $anim_drawing
const ATK_TIMER = 0.015
var _speed = Vector2(0.01,0.01)
var _got_too_big:bool = false
var _atk_timer: float = 0.0
var _atk_prev_timer: float = 0.0
var _id: int = 0
signal aoe_attack_hit()

func _ready():
	scale = Vector2(2,2)
	drawing.play("default")

func _process(delta):
	_atk_timer += delta
	if (_atk_timer - _atk_prev_timer > ATK_TIMER):
		scale += _speed
		_speed.x += 0.0008
		_speed.y += 0.0008
		if scale > Vector2(150,150):
			modulate.a8 -= 1
		_atk_prev_timer = _atk_timer
	if Vector2(200,200) < scale:
		_got_too_big = true
		emit_signal("aoe_attack_hit")

func _on_AoEAttack_area_entered(area):
	if not _got_too_big and area.is_in_group("player"):
		get_parent().player.take_damage(5)
		emit_signal("aoe_attack_hit")

func set_id(x:int) -> void:
	_id = x

func get_id() -> int:
	return _id
