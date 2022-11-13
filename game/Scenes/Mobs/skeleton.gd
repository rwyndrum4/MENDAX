"""
Revision date: 11/12/22 - Freeman added physics process
"""


extends KinematicBody2D
onready var skeleton = $Position2D/AnimatedSprite
onready var healthbar = $ProgressBar
onready var skeleBox = $MyHurtBox/hitbox
var isDead = 0

# critter physics constants
const ACCELERATION = 25000
const MAX_SPEED = 500
const FRICTION = 500

# Global velocity
var velocity = Vector2.ZERO
var targetFound = true
var targetPosition = Vector2.ZERO

func _ready():
	skeleton.play("idle")
	healthbar.value = 100;
	
"""
/*
* @pre Called every frame
* @post x and y velocity of the PlayerCursor element is updated to reflect the current player input (given by pressing WASD)
* @param delta : elapsed time (in seconds) since previous frame. Should be constant across sequential calls
* @return None
*/
"""	
func _physics_process(delta):
	if targetFound:
		velocity = velocity.move_toward(50*.position, FRICTION*delta)
	else:
		velocity = velocity.move_toward(Vector2.ZERO, FRICTION*delta)
	
	velocity = move_and_slide(velocity)

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


func _on_mySearchBox_body_exited(body):
	targetFound = false
