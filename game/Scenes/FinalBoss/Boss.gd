extends StaticBody2D
var _timer:float = 0
var _prev_timer:float = 0

var aoe_attack = preload("res://Scenes/BossAttacks/AoeSlam.tscn")

func spawn_aoe_attack() -> void:
	var rng = RandomNumberGenerator.new()
	rng.randomize()
	var randomSector = rng.randi_range(1, 3)
	var randomX: int = 0
	var randomY: int = 0
	if randomSector == 1:
		randomX = rng.randi_range(-2000, 5000)
		randomY = rng.randi_range(-1000, 5000)
	elif randomSector == 2:
		randomX = rng.randi_range(-11000, -5000)
		randomY = rng.randi_range(2500, 7500)
	else:
		randomX = rng.randi_range(-6500, -2500)
		randomY = rng.randi_range(2600, 3400)
	var atk = aoe_attack.instance()
	atk.position = Vector2(randomX, randomY)
	get_parent().add_child(atk)
	atk.connect("aoe_attack_hit",self,"_delete_aoe_atk", [atk])

func _delete_aoe_atk(atk:Area2D) -> void:
	atk.queue_free()
	
func _process(delta):
	_timer += delta
	if _timer - _prev_timer > 2:
		spawn_aoe_attack()
		_prev_timer = _timer
