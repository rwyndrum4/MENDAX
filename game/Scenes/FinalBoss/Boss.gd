extends StaticBody2D
var _timer:float = 0
var _prev_timer:float = 0
var _dmgCap

var aoe_attack = preload("res://Scenes/BossAttacks/AoeSlam.tscn")
var boulder = preload("res://Scenes/BossAttacks/Boulder.tscn")
var atkWarningAnimation = preload("res://Scenes/BossAttacks/atkWarning.tscn")

onready var healthbar = $ProgressBar
onready var bossBox = $MyHurtBox/hitbox

"""
/*
* @pre Called once when boss is initialized
* @post Initializes boss health
* @param None
* @return None
*/
"""
func _ready():
	healthbar.value = 100;

func move_boss() -> void:
	position.y -= 100
	var back_timer = Timer.new()
	back_timer.one_shot = true
	back_timer.wait_time = 0.5
	add_child(back_timer)
	back_timer.connect("timeout",self,"_del_timer",[back_timer])
	back_timer.start()

func _del_timer(tmr):
	position.y += 100
	tmr.queue_free()

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
	var ran_pos = Vector2(randomX,randomY)
	var atk = aoe_attack.instance()
	var bdr = boulder.instance()
	var warAni = atkWarningAnimation.instance()
	var x_sprite = Sprite.new()
	x_sprite.texture = load("res://Assets/final_boss_attack/character_atk/x.png")
	x_sprite.scale = Vector2(2,2)
	x_sprite.position = ran_pos
	warAni.position = Vector2(position.x + 600, position.y)
	warAni.rotate(0.2)
	warAni.scale = Vector2(5,5)
	bdr.position = Vector2(randomX,randomY - 1000)
	bdr.set_final_pos(ran_pos)
	atk.position = ran_pos
	get_parent().add_child(warAni)
	warAni.connect("animation_finished",self,"_del_animation",[warAni])
	get_parent().add_child(x_sprite)
	get_parent().add_child(bdr)
	bdr.connect("boulder_done",self,"_atk_can_go", [atk,x_sprite])

func _del_animation(warAni):
	warAni.queue_free()

func _atk_can_go(atk,x_sprite):
	x_sprite.queue_free()
	get_parent().add_child(atk)
	atk.connect("aoe_attack_hit",self,"_delete_aoe_atk", [atk])

func _delete_aoe_atk(atk:Area2D) -> void:
	atk.queue_free()
	
func _process(delta):
	_timer += delta
	if _timer - _prev_timer > 2:
		move_boss()
		spawn_aoe_attack()
		_prev_timer = _timer
		
"""
/*
* @pre Called by when it detects a "hit" from a hitbox
* @post Mob takes damage and is reflected by the healthbar
* @param Takes in a damage value
* @return None
*/
"""
func take_damage(amount: int) -> void:
	ServerConnection.send_arena_enemy_hit(amount,1) #1 is the type of enemy, reference EnemyTypes in arenaGame.gd
	healthbar.value = healthbar.value - amount

	if healthbar.value == 50:
		Global.state = Global.scenes.QUIZ

#Same function as above but doesn't send data to the server
func take_damage_server(amount: int):
	healthbar.value = healthbar.value - amount
	if healthbar.value == 50:
		Global.state = Global.scenes.QUIZ

