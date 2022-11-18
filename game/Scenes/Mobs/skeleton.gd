"""
Revision date: 11/12/2022 - Freeman added physics process
			   11/13/2022 - Moved all of physics process except member variables to arenaGame
			   11/15/2022 - Improved targeting system with addition of a second Area2D radius.
							Moved Skeleton physics process back into this file
"""


extends KinematicBody2D
onready var skeletonAnim = $AnimationPlayer
onready var healthbar = $ProgressBar
onready var skeleBox = $MyHurtBox/hitbox
onready var skeleAtkBox = $MyHitBox/CollisionShape2D

var isIn = false
var isDead = 0

# Global velocity
var velocity = Vector2.ZERO
var targetFound = true

func _ready():
	var anim = get_node("AnimationPlayer").get_animation("idle")
	anim.set_loop(true)
	skeletonAnim.play("idle")
	healthbar.value = 100;
	
"""
/*
* @pre Called every frame
* @post x an y velocity of the Skeleton is updated to move towards the player (if the player is within it's Search range)
* @param delta : elapsed time (in seconds) since previous frame. Should be constant across sequential calls
* @return None
*/
"""		
func _physics_process(delta):
	if targetFound:
		velocity = move_and_slide(velocity.move_toward(0.7*(get_parent().get_node("Player").position - position), 500*delta))
	else:
		velocity = move_and_slide(velocity.move_toward(0.7*Vector2.ZERO, 500*delta))

func take_damage(amount: int) -> void:
	
	healthbar.value = healthbar.value - amount
	skeletonAnim.play("hit")
	print(healthbar.value)
	if healthbar.value == 0:
		skeletonAnim.play("death")
		skeleBox.disabled = true
		isDead = 1

func _on_AnimationPlayer_animation_finished(anim_name):
		
	if !isDead:
		if !isIn:			
			skeletonAnim.play("idle")
		else:
			skeletonAnim.play("attack1")
	else:
		queue_free()


func _on_mySearchBox_body_entered(_body:PhysicsBody2D):
	targetFound = true

func _on_myLostBox_body_exited(_body:PhysicsBody2D):
	targetFound = false

func _on_detector_body_entered(body):
	isIn = true
	skeletonAnim.play("attack1")
	
func _on_detector_body_exited(body):
	isIn = false
