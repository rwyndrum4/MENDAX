"""
Revision date: 11/12/2022 - Freeman added physics process
			   11/13/2022 - Moved all of physics process except member variables to arenaGame
			   11/15/2022 - Improved targeting system with addition of a second Area2D radius.
							Moved Skeleton physics process back into this file
"""


extends KinematicBody2D
onready var skeleton = $Position2D/AnimatedSprite
onready var healthbar = $ProgressBar
onready var skeleBox = $MyHurtBox/hitbox
var isDead = 0

# Global velocity
var velocity = Vector2.ZERO
var targetFound = true

func _ready():
	skeleton.play("idle")
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
	skeleton.play("hit")
	print(healthbar.value)
	if healthbar.value == 0:
		skeleton.play("death")
		skeleBox.disabled = true
		isDead = 1

func _on_AnimatedSprite_animation_finished():
	
	if !isDead:
		skeleton.play("idle")
	else:
		queue_free()


func _on_mySearchBox_body_entered(_body:PhysicsBody2D):
	targetFound = true


func _on_myLostBox_body_exited(body):
	targetFound = false
