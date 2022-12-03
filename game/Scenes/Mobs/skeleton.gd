"""
* Programmer Name - Jason Truong and Freeman Spray
* Description - Code that designates mob animations
* Date Created - 11/11/2022
* Revision date: 11/12/2022 - Freeman added physics process
			   11/13/2022 - Moved all of physics process except member variables to arenaGame
			   11/15/2022 - Improved targeting system with addition of a second Area2D radius.
							Moved Skeleton physics process back into this file
			   11/19/2022 - Changed signal names to not cause errors anymore
			   11/28/2022 - Added death signal
			
"""


extends KinematicBody2D
onready var skeletonAnim = $skeletonAnimationPlayer
onready var healthbar = $ProgressBar
onready var skeleBox = $MyHurtBox/hitbox
onready var skeleAtkBox = $MyHitBox/CollisionShape2D
onready var pos2d = $Position2D
onready var player_detector_box = $detector/box

var isIn = false
var isDead = 0

# Global velocity
var velocity = Vector2.ZERO
var BASE_SPEED = 0.7
var BASE_ACCEL = 500
var targetFound = true

"""
/*
* @pre Called once when mob is initialized
* @post Makes idle animation loop and initializes the health
* @param None
* @return None
*/
"""
func _ready():
	var anim = get_node("skeletonAnimationPlayer").get_animation("idle")
	anim.set_loop(true)
	skeletonAnim.play("idle")
	healthbar.value = 100;
	# warning-ignore:return_value_discarded
	ServerConnection.connect("arena_enemy_hit",self, "took_damage_from_server")
	# warning-ignore:return_value_discarded
	GlobalSignals.connect("textbox_empty",self,"turn_on_physics")
	
"""
/*
* @pre Called every frame
* @post x an y velocity of the Skeleton is updated to move towards the player (if the player is within it's Search range)
* @param delta : elapsed time (in seconds) since previous frame. Should be constant across sequential calls
* @return None
*/
"""		
func _physics_process(delta):
	var player_pos = null
	#Check if player 1 is there
	if not get_parent()._player_dead:
		player_pos = get_parent().get_node("Player").position
	else:
		velocity = move_and_slide(velocity.move_toward(BASE_SPEED*Vector2.ZERO, BASE_ACCEL*delta))
		return
#	#Handle chasing down player
#	if targetFound:
#		velocity = move_and_slide(velocity.move_toward(BASE_SPEED*(player_pos - position), 500*delta))
#	else:
#		velocity = move_and_slide(velocity.move_toward(BASE_SPEED*Vector2.ZERO, 500*delta))
	velocity = move_and_slide(velocity.move_toward(BASE_SPEED*(player_pos - position), BASE_ACCEL*delta))
	#Handle making skeleton turn around
	if player_pos.x < position.x:
		pos2d.scale.x = -1
		player_detector_box.position = Vector2(-50,0)
		skeleAtkBox.position = Vector2(-40,0)
	else:
		pos2d.scale.x = 1
		player_detector_box.position = Vector2(50,0)
		skeleAtkBox.position = Vector2(60,0)

func turn_on_physics():
	set_physics_process(true)

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
	skeletonAnim.play("hit")
	if healthbar.value == 0:
		skeletonAnim.play("death")
		#have to defer disabling the skeleton, got an error otherwise
		#put the line of code in function below since call_deferred only takes functions as input
		call_deferred("defer_disabling_skeleton")
		isDead = 1

func take_damage_server(amount: int):
	healthbar.value = healthbar.value - amount
	skeletonAnim.play("hit")
	if healthbar.value == 0:
		skeletonAnim.play("death")
		#have to defer disabling the skeleton, got an error otherwise
		#put the line of code in function below since call_deferred only takes functions as input
		call_deferred("defer_disabling_skeleton")
		isDead = 1

func defer_disabling_skeleton():
	skeleBox.disabled = true

"""
/*
* @pre Called when player enters the Skeleton's search radius
* @post sets targetFound to true so the Skeleton can begin moving towards the player in its physics process
* @param _body -> body of the player (unused)
* @return None
*/
"""
func _on_mySearchBox_body_entered(_body:PhysicsBody2D):
	targetFound = true

"""
/*
* @pre Called when player exits the Skeleton's anti-search radius
* @post sets targetFound to false so the Skeleton will no longer move towards the player in its physics process
* @param _body -> body of the player (unused)
* @return None
*/
"""
func _on_myLostBox_body_exited(_body:PhysicsBody2D):
	targetFound = false
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

"""
/*
* @pre Called once animation is finished
* @post Dequeue's the mob if isDead is true otherwise plays an animation
* @param None
* @return None
*/
"""
func _on_skeletonAnimationPlayer_animation_finished(_anim_name):
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
* @pre timer in arenaGame has expired
* @post make Skeleton tougher
* @param None
* @return None
*/
"""
func level_up():
	healthbar.value = healthbar.value + 40
	BASE_SPEED = 1.6
	BASE_ACCEL = 1000
	$MyHitBox.damage = 30
