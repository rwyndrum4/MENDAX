"""
* Programmer Name - Freeman Spray, Ben Moeller
* Description - Code for controlling the boss enemy
* Date Created - 2/19/2023
* Date Revisions:
	2/26/2022 - Added health bar
	3/10/2023 - Added invulnerability
"""
extends StaticBody2D

const TP_TIMER = 32 #timer to use for boss teleport
const ANI_TIMER = 2 #timer to use for boss animation and attack

var _tp_counter:int = 0 #counter for what part of array to index
var _random_numbers:Array = [] #sort of "random" numbers for boss to tp to
var _atk_timer:float = 0
var _atk_prev_timer:float = 0
var _tp_timer:float = 0
var _tp_prev_timer:float = 0
var _invulnerable
var _can_teleport:bool = false #lets boss know if they can tp or not

var aoe_attack = preload("res://Scenes/BossAttacks/AoeSlam.tscn")
var boulder = preload("res://Scenes/BossAttacks/Boulder.tscn")
var atkWarningAnimation = preload("res://Scenes/BossAttacks/atkWarning.tscn")

onready var healthbar = $ProgressBar
onready var bossBox = $MyHurtBox/hitbox
onready var auraShield = $aura_shield

"""
* @pre Called once when boss is initialized
* @post Initializes boss health
* @param None
* @return None
"""
func _ready():
	position = Vector2(-4250, 2400)
	# warning-ignore:return_value_discarded
	ServerConnection.connect("boss_is_vulnerable", self, "_set_invulnerability")
	if ServerConnection.match_exists() and ServerConnection.get_server_status():
		var num_players = len(Global.player_names)
		for i in range(8):
			i *= 17
			var new_rand = (i * num_players) % 4
			if new_rand == _random_numbers[i-1]:
				new_rand = new_rand + 1 if (new_rand + 1) < 4 else new_rand - 1
			_random_numbers.append(new_rand)
	else:
		_random_numbers = [3,1,0,2]
	print("progress: " + str(Global.progress))
	if Global.progress == 8:
		_can_teleport = false
		healthbar.value = 200
		_invulnerable = true;
		auraShield.visible = true
	else:
		#In all other phases allow the boss to teleport
		_can_teleport = true
		healthbar.value = 400
		_invulnerable = false;
		auraShield.visible = false

"""
* @pre Called in the process function whenever an attack occurs
* @post Animates boss
* @param None
* @return None
"""
func move_boss() -> void:
	position.y -= 100
	var back_timer = Timer.new()
	back_timer.one_shot = true
	back_timer.wait_time = 0.5
	add_child(back_timer)
	back_timer.connect("timeout",self,"_del_timer",[back_timer])
	back_timer.start()

"""
* @pre Called if in phases where boss can telport
* @post changes position to predetermined location (random for len(pos_arr))
* @param None
* @return None
"""
func teleport_boss() -> void:
	var pos_arr = [
		[Vector2(-4250, 2400), "the middle of the map"],
		[Vector2(-8700, 5500), "the bottom left side of the map"],
		[Vector2(2500, 3000), "the bottom right side of the map"],
		[Vector2(1500, 500), "the top right side of the map"]
	]
	GlobalSignals.emit_signal(
		"exportEventMessage",
		"Boss teleported to " + str(pos_arr[_tp_counter][1]),
		"pink"
	)
	position = pos_arr[_tp_counter][0]
	_tp_counter += 1
	if _tp_counter >= len(_random_numbers):
		_tp_counter = 0

"""
/*
* @pre Called by a timeout signal connected in the cleanup process of move_boss()
* @post Frees timer
* @param tmr, a timer.
* @return None
*/
"""
func _del_timer(tmr):
	position.y += 100
	tmr.queue_free()

"""
/*
* @pre Called in the process function
* @post spawns an aoe attack
* @param None
* @return None
*/
"""
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
	

"""
/*
* @pre Called by a completion signal connected in the cleanup process of spawn_aoe_attack()
* @post Frees animation
* @param warAni, an animation node.
* @return None
*/
"""
func _del_animation(warAni):
	warAni.queue_free()

"""
/*
* @pre Called by a completion signal connected in the cleanup process of spawn_aoe_attack()
* @post 
* @param atk, an Area2D node. x_sprite, a sprite
* @return None
*/
"""
func _atk_can_go(atk,x_sprite):
	x_sprite.queue_free()
	get_parent().add_child(atk)
	atk.connect("aoe_attack_hit",self,"_delete_aoe_atk", [atk])

"""
/*
* @pre Called by a completion signal connected in the cleanup process of _atk_can_go()
* @post Frees timer
* @param atk, an Area2D node.
* @return None
*/
"""
func _delete_aoe_atk(atk:Area2D) -> void:
	atk.queue_free()

"""
/*
* @pre Called every frame
* @post Spawns attacks based on the timer
* @param delta, the time between frames
* @return None
*/
"""
func _process(delta):
	_atk_timer += delta
	_tp_timer += delta
	#Clause to make boss shift (not teleport) and spawn attack
	if (_atk_timer - _atk_prev_timer > ANI_TIMER):
		move_boss()
		spawn_aoe_attack()
		_atk_prev_timer = _atk_timer
	#If can teleport and timer premits, do it
	if _can_teleport and (_tp_timer - _tp_prev_timer > TP_TIMER):
		teleport_boss()
		_tp_prev_timer = _tp_timer
	#Show aura shield if boss is invincible
	if _invulnerable == true:
		auraShield.visible = true
	else:
		auraShield.visible = false
"""
/*
* @pre Called by when it detects a "hit" from a hitbox
* @post Mob takes damage and is reflected by the healthbar
* @param Takes in a damage value
* @return None
*/
"""
func take_damage(amount: int) -> void:
	ServerConnection.send_arena_enemy_hit(amount,0, "Boss")
	if _invulnerable == false:
		healthbar.value = healthbar.value - amount
		if healthbar.value == 200 and Global.progress == 6:
			Global.state = Global.scenes.QUIZ
		if healthbar.value == 0:
			Global.state = Global.scenes.END_SCREEN

#Same function as above but doesn't send data to the server
func take_damage_server(amount: int) -> void:
	healthbar.value = healthbar.value - amount
	if healthbar.value == 200 and Global.progress == 6:
		Global.state = Global.scenes.QUIZ
	if healthbar.value == 0:
		Global.state = Global.scenes.END_SCREEN

"""
* @pre Called when a player meets conditions to start/stop invulnerability
* @post boss invulnerability is changed
* @param val (true = can't hit, false = can hit)
* @return None
"""
func _set_invulnerability(val:bool) -> void:
	_invulnerable = val

"""
* @pre None
* @post returns vulnerable status
* @param None
* @return bool
"""
func get_vulnerable_status() -> bool:
	return _invulnerable
