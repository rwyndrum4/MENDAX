"""
* Programmer Name - Jason Truong
* Description - Code that designates mob animations
* Date Created - 11/20/2022
* Date Revisions:
"""
extends KinematicBody2D
onready var BodAnim = $AnimationPlayer
onready var healthbar = $ProgressBar
onready var BodBox = $MyHurtBox/hitbox
onready var BodAtkBox = $MyHitBox/CollisionShape2D
onready var pos2d = $Position2D
onready var player_detector_box = $detector/box

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
	BodAnim.play("idle")
	healthbar.value = 200;

"""
/*
* @pre Called every frame
* @post x an y velocity of the Skeleton is updated to move towards the player (if the player is within it's Search range)
* @param delta : elapsed time (in seconds) since previous frame. Should be constant across sequential calls
* @return None
*/
"""		
func _physics_process(_delta):
	var player_pos = null
	if not get_parent()._player_dead:
		player_pos = get_parent().get_node("Player").position
	else:
		return
	#Handle making skeleton turn around
	if player_pos.x < position.x:
		pos2d.scale.x = 1
		player_detector_box.position = Vector2(-70,-6)
		BodAtkBox.position = Vector2(-60,-5)
	else:
		pos2d.scale.x = -1
		player_detector_box.position = Vector2(70,-5)
		BodAtkBox.position = Vector2(80,-6)

"""
/*
* @pre Called by when it detects a "hit" from a hitbox
* @post Mob takes damage and is reflected by the healthbar
* @param Takes in a damage value
* @return None
*/
"""
func take_damage(amount: int) -> void:
	ServerConnection.send_arena_enemy_hit(amount,3) #3 is the type of enemy, reference EnemyTypes in arenaGame.gd
	healthbar.value = healthbar.value - amount
	BodAnim.play("hit")
	if healthbar.value == 0:
		BodAnim.play("death")
		call_deferred("defer_disabling_BoD")
		isDead = 1
		
func defer_disabling_BoD():
	BodBox.disabled = true

#Same as above function except it doesn't send data to server
func take_damage_server(amount: int):
	healthbar.value = healthbar.value - amount
	BodAnim.play("hit")
	if healthbar.value == 0:
		BodAnim.play("death")
		call_deferred("defer_disabling_BoD")
		isDead = 1

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
			BodAnim.play("idle")
		else:
			BodAnim.play("attack1")
	else:
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
	BodAnim.play("attack1")
	


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
