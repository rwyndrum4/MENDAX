"""
* Programmer Name - Jason Truong
* Description - Code that designates mob animations
* Date Created - 11/20/2022
* Date Revisions:
	12/3/2022 - Chandelier can shoot fireballs
"""
extends KinematicBody2D
onready var chandelierAnim = $AnimationPlayer
onready var healthbar = $ProgressBar
onready var chandelierBox = $MyHurtBox/hitbox
onready var chandelierAtkBox = $MyHitBox/CollisionShape2D

var _isIn = false
var _isDead = 0
var _leveled_up: bool = false

#motion vector for enemy
var _motion=Vector2()
var _timer=0;
var _fire_wait_time: int = 4
"""
/*
* @pre Called once when mob is initialized
* @post Makes idle animation loop and initializes the health
* @param None
* @return None
*/
"""
func _ready():
	var anim = get_node("AnimationPlayer").get_animation("idle")
	anim.set_loop(true)
	chandelierAnim.play("idle")
	healthbar.value = 200;
	# warning-ignore:return_value_discarded
	GlobalSignals.connect("textbox_empty",self,"turn_on_physics")
	position=Vector2(500,500)

"""
/*
* @pre Called every frame
* @post x an y velocity of the Skeleton is updated to move towards the player (if the player is within it's Search range)
* @param delta : elapsed time (in seconds) since previous frame. Should be constant across sequential calls
* @return None
*/
"""
func _physics_process(delta):
	_timer+=delta
	if _timer > _fire_wait_time:
		_timer=0;
		chandelierAnim.play("attack1")
		yield(chandelierAnim, "animation_finished")
		fire();
		if _leveled_up:
			fire(Vector2(-200, -200))
			fire(Vector2(-100, -100))
			fire(Vector2(100, 100))
			fire(Vector2(200, 200))
		chandelierAnim.play("idle")

"""
/*
* @pre Text Box queue is empty
* @post turns back on the physics process, aka can now move
* @param None
* @return None
*/
"""	
func turn_on_physics():
	set_physics_process(true)

"""
/*
* @pre Chandelier is ready to fire
* @post Fires bullet towoards player
* @param extra_angle -> Vector2 (extra angles to fire at)
* @return None
*/
"""	
func fire(extra_angle = Vector2(0,0)):
	if get_parent()._player_dead:
		return
	var Player=get_parent().get_node("Player")
	var bullete =preload("res://Scenes/bullet/bulletenemy.tscn")
	var bulenemy = bullete.instance()
	get_parent().add_child(bulenemy)
	bulenemy.global_position = global_position + Vector2(0, -90)
	bulenemy.velocity = bulenemy.global_position.direction_to(
		Player.global_position + extra_angle
	)

"""
/*
* @pre Called by when it detects a "hit" from a hitbox
* @post Mob takes damage and is reflected by the healthbar
* @param Takes in a damage value
* @return None
*/
"""
func take_damage(amount: int) -> void:
	ServerConnection.send_arena_enemy_hit(amount,2)
	healthbar.value = healthbar.value - amount
	chandelierAnim.play("hit")
	if healthbar.value == 0:
		chandelierAnim.play("death")
		call_deferred("defer_disabling_chandelier")
		_isDead = 1
	
#Same as above function except it doesn't send data to server
func take_damage_server(amount: int):
	healthbar.value = healthbar.value - amount
	chandelierAnim.play("hit")
	if healthbar.value == 0:
		chandelierAnim.play("death")
		call_deferred("defer_disabling_BoD")
		_isDead = 1

func defer_disabling_chandelier():
	chandelierBox.disabled = true

"""
/*
* @pre Called once animation is finished
* @post Dequeue's the mob if isDead is true otherwise plays an animation
* @param None
* @return None
*/
"""
func _on_AnimationPlayer_animation_finished(_anim_name):
		
	if !_isDead:
		#if !isIn:			
		#	chandelierAnim.play("idle")
		#else:
		#	chandelierAnim.play("attack1")
		pass
	else:
		GlobalSignals.emit_signal("enemyDefeated", 0) #replace 0 with indication of enemy ID later
		queue_free()

"""
/*
* @pre Called when it detects a body entering its 2D area
* @post isIn is set to true
* @param None
* @return None
*/
"""
func _on_detector_body_entered(_body):
	_isIn = true
	#chandelierAnim.play("attack1")
	


"""
/*
* @pre Called once a body leaves the 2D area
* @post isIn is set to false
* @param None
* @return None
*/
"""
func _on_detector_body_exited(_body):
	_isIn = false

func level_up():
	_leveled_up = true
	_fire_wait_time = 1
	healthbar.value = healthbar.value + 40
	#New timer that makes it so that BoD teleports ever 4 sec
	var teleport_timer: Timer = Timer.new()
	add_child(teleport_timer)
	teleport_timer.wait_time = 10
	teleport_timer.one_shot = false
	teleport_timer.start()
	# warning-ignore:return_value_discarded
	teleport_timer.connect("timeout",self, "_tp_timer_expired")

"""
/*
* @pre timer defined above has expired
* @post makes BoD telport to player
* @param None
* @return None
*/
"""
func _tp_timer_expired():
	var x = randi() % 3500 + 500
	var y = randi() % 3250 + 500
	position = Vector2(x,y)
