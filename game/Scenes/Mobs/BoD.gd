"""
* Programmer Name - Jason Truong
* Description - Code that designates mob animations
* Date Created - 11/20/2022
* Date Revisions: - 11/28/2022 - add death signal
"""
extends KinematicBody2D
onready var skeletonAnim = $AnimationPlayer
onready var healthbar = $ProgressBar
onready var skeleBox = $MyHurtBox/hitbox
onready var skeleAtkBox = $MyHitBox/CollisionShape2D

var isIn = false
var isDead = 0

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
	skeletonAnim.play("idle")
	healthbar.value = 200;

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
	skeletonAnim.play("hit")
	print(healthbar.value)
	if healthbar.value == 0:
		skeletonAnim.play("death")
		call_deferred("defer_disabling_BoD")
		isDead = 1
		
func defer_disabling_BoD():
	skeleBox.disabled = true

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
		if !isIn:			
			skeletonAnim.play("idle")
		else:
			skeletonAnim.play("attack1")
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
	skeletonAnim.play("attack1")
	


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
