"""
* Programmer Name - Freeman Spray, Ben Moeller
* Description - Code for controlling the boss enemy
* Date Created - 2/19/2023
* Date Revisions:
	2/26/2022 - Added health bar
	3/10/2023 - Added invulnerability
"""
extends StaticBody2D

const TP_TIMER = 40 #timer to use for boss teleport
const ANI_TIMER = 2 #timer to use for boss animation and attack

var _random_numbers:Array = [0,3,1,2,0,1,2,3,0,1,0,3,2] #sort of "random" numbers for boss to tp to
#Array that holds positions where boss can teleport too
var _pos_arr = [
		[Vector2(-4250, 2400), "the middle of the map"],
		[Vector2(-8700, 5500), "the bottom left side of the map"],
		[Vector2(2500, 3000), "the bottom right side of the map"],
		[Vector2(1500, 500), "the top right side of the map"]
	]
#Timer variables, used in process function
###############################
var _atk_timer:float = 0
var _atk_prev_timer:float = 0
var _tp_timer:float = 0
var _tp_prev_timer:float = 0
###############################
var _invulnerable #variable to track if boss is vulnerable or not
var _can_teleport:bool = false #lets boss know if they can tp or not
var _aoe_pos_ctr:int = 0 #counter to support where to index into array below
#positions where an aoe attack can be dropped
var _atk_positions: Array = [
		Vector2(-5000,3000),
		Vector2(0, 2000),
		Vector2(-7000,5000),
		Vector2(-3000,3000),
		Vector2(2000,3000),
		Vector2(-4000,3000),
		Vector2(-9500,5500),
		Vector2(-2500,3000),
		Vector2(1250,500),
		Vector2(-9000,6000),
		Vector2(-3250,3250),
		Vector2(-7500,3100),
		Vector2(-100,3000)
	]
var _atk_objects: Dictionary = {} #array to store objects of aoe attacks

#Objects
var aoe_attack = preload("res://Scenes/BossAttacks/AoeSlam.tscn")
var boulder = preload("res://Scenes/BossAttacks/Boulder.tscn")
var atkWarningAnimation = preload("res://Scenes/BossAttacks/atkWarning.tscn")

#Scene Objects
onready var healthbar = $GUI/ProgressBar
onready var bossBox = $MyHurtBox/hitbox
onready var auraShield = $aura_shield

"""
* @pre Called once when boss is initialized
* @post Initializes boss health
* @param None
* @return None
"""
func _ready():
	#Set initial position of boss based on past experiences
	var c = _random_numbers[Global._boss_tp_counter]
	position = _pos_arr[c][0]
	if not Global._first_time_in_boss:
		Global._first_time_in_boss = true
	else:
		Global._boss_tp_counter += 1
		GlobalSignals.emit_signal(
			"exportEventMessage",
			"Boss teleported to " + str(_pos_arr[c][1]),
			"pink"
		)
	# warning-ignore:return_value_discarded
	ServerConnection.connect("boss_is_vulnerable", self, "_set_invulnerability")
	# warning-ignore:return_value_discarded
	ServerConnection.connect("aoe_attack_was_hit", self, "_delete_atk_from_server")
	if Global.progress == 0:
		_can_teleport = false
		_invulnerable = true
		healthbar.value = 400
		auraShield.visible = true
	elif Global.progress == 8:
		#In all other phases allow the boss to teleport
		_can_teleport = true
		_invulnerable = true
		healthbar.value = 400
		auraShield.visible = false
	else:
		#In all other phases allow the boss to teleport
		_can_teleport = true
		_invulnerable = false
		healthbar.value = 400
		auraShield.visible = false

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
* @pre Called in the process function whenever an attack occurs
* @post Animates boss
* @param None
* @return None
"""
func move_boss() -> void:
	$MyHurtBox/hitbox.hide()
	$MyHurtBox/hitbox.disabled = true
	$MyHurtBox/hitboxDuck.show()
	$MyHurtBox/hitboxDuck.disabled = false
	$Sprite.hide()
	$DuckSprite.show()
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
	var c = _random_numbers[Global._boss_tp_counter]
	GlobalSignals.emit_signal(
		"exportEventMessage",
		"Boss teleported to " + str(_pos_arr[c][1]),
		"pink"
	)
	position = _pos_arr[c][0]
	Global._boss_tp_counter += 1
	if Global._boss_tp_counter >= len(_random_numbers):
		Global._boss_tp_counter = 0

"""
/*
* @pre Called in the process function
* @post spawns an aoe attack
* @param None
* @return None
*/
"""
func spawn_aoe_attack() -> void:
	var atk_pos = get_aoe_pos() #get position of attack
	var atk = aoe_attack.instance()
	var bdr = boulder.instance()
	var warAni = atkWarningAnimation.instance()
	var x_sprite = Sprite.new()
	x_sprite.texture = load("res://Assets/final_boss_attack/character_atk/x.png")
	x_sprite.scale = Vector2(2,2)
	x_sprite.position = atk_pos
	warAni.position = Vector2(position.x + 600, position.y)
	warAni.rotate(0.2)
	warAni.scale = Vector2(5,5)
	bdr.position = Vector2(atk_pos.x,atk_pos.y - 1000)
	bdr.set_final_pos(atk_pos)
	atk.position = atk_pos
	#add attack to parent scene
	get_parent().add_child(warAni)
	warAni.connect("animation_finished",self,"_del_animation",[warAni])
	get_parent().add_child(x_sprite)
	get_parent().add_child(bdr)
	bdr.connect("boulder_done",self,"_atk_can_go", [atk,x_sprite])

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
		if healthbar.value <= 200 and Global.progress == 6:
			Global.state = Global.scenes.QUIZ
		if healthbar.value == 0:
			Global.state = Global.scenes.END_SCREEN

#Same function as above but doesn't send data to the server
func take_damage_server(amount: int) -> void:
	healthbar.value = healthbar.value - amount
	if healthbar.value <= 200 and Global.progress == 6:
		Global.state = Global.scenes.QUIZ
	if healthbar.value == 0:
		Global.state = Global.scenes.END_SCREEN

"""
* @pre None
* @post returns vulnerable status
* @param None
* @return bool
"""
func get_vulnerable_status() -> bool:
	return _invulnerable

"""
* @pre None
* @post returns a position to spawn an AOE attack at
* @param None
* @return bool
"""
func get_aoe_pos() -> Vector2:
	var final = _atk_positions[_aoe_pos_ctr]
	_aoe_pos_ctr += 1
	if _aoe_pos_ctr >= len(_atk_positions):
		_aoe_pos_ctr = 0
	return final

"""
* @pre Some other player interracted with an aoe attack
* @post deletes the aoe attack if it has not already
* @param atk_id -> int (id of the attack)
* @return None
"""
func _delete_atk_from_server(atk_id:int) -> void:
	var cur_atk = _atk_objects.get(atk_id)
	if is_instance_valid(cur_atk):
		cur_atk.queue_free()

"""
/*
* @pre Called by a timeout signal connected in the cleanup process of move_boss()
* @post Frees timer
* @param tmr, a timer.
* @return None
*/
"""
func _del_timer(tmr):
	$MyHurtBox/hitbox.show()
	$MyHurtBox/hitbox.disabled = false
	$MyHurtBox/hitboxDuck.hide()
	$MyHurtBox/hitboxDuck.disabled = true
	$Sprite.show()
	$DuckSprite.hide()
	tmr.queue_free()

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
* @pre Called when the boulder finished its animation
* @post Aoe attack starts
* @param atk, an Area2D node. x_sprite, a sprite
* @return None
*/
"""
func _atk_can_go(atk,x_sprite):
	x_sprite.queue_free()
	var id = len(_atk_objects)
	if is_instance_valid(atk):
		atk.set_id(id)
		get_parent().add_child(atk)
		_atk_objects[id] = atk
		atk.connect("aoe_attack_hit",self,"_delete_aoe_atk", [atk])

"""
/*
* @pre Called whenever an attack hits the main person
* @post If attack is valid, tell other players it is gone, then delete it
* @param atk, an Area2D node.
* @return None
*/
"""
func _delete_aoe_atk(atk:Area2D) -> void:
	if is_instance_valid(atk):
		ServerConnection.send_aoe_atk_hit(atk.get_id())
		atk.disconnect("aoe_attack_hit", self, "_delete_aoe_atk")
		atk.queue_free()

"""
* @pre Called when a player meets conditions to start/stop invulnerability
* @post boss invulnerability is changed
* @param val (true = can't hit, false = can hit)
* @return None
"""
func _set_invulnerability(val:bool) -> void:
	_invulnerable = val
