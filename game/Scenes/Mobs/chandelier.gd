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

var isIn = false
var isDead = 0

#motion vector for enemy
var motion=Vector2()
var timer=0;
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


func _physics_process(delta):
	##position +=(Player.position-position)/50 #enemy moves toward player
	position=Vector2(500,500)
	
	#move_and_collide(motion)
	timer+=delta
	#print(timer)
	if timer>4:
		timer=0;
		chandelierAnim.play("attack1")
		yield(chandelierAnim, "animation_finished")
		fire();
		chandelierAnim.play("idle")
		
		

var bullete =preload("res://Scenes/bullet/bulletenemy.tscn")
func fire():
	if get_parent()._player_dead:
		return
	var Player=get_parent().get_node("Player")
	var bulenemy = bullete.instance()
	
	#get_tree().get_root().add_child(bulenemy)
	get_parent().add_child(bulenemy)
	if get_parent()._player_dead == false:
		bulenemy.global_position = global_position + Vector2(0, -90)
		bulenemy.velocity=bulenemy.global_position.direction_to(Player.global_position)
	print(bulenemy.velocity)

"""
/*
* @pre Called by when it detects a "hit" from a hitbox
* @post Mob takes damage and is reflected by the healthbar
* @param Takes in a damage value
* @return None
*/
"""
func take_damage(amount: int) -> void:
	
	healthbar.value = healthbar.value - amount
	chandelierAnim.play("hit")
	print(healthbar.value)
	if healthbar.value == 0:
		chandelierAnim.play("death")
		isDead = 1
		#have to defer disabling the skeleton, got an error otherwise
		#put the line of code in function below since call_deferred only takes functions as input
		call_deferred("defer_disabling_chandelier")
		isDead = 1

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
		
	if !isDead:
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
	isIn = true
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
	isIn = false
