"""
* Programmer Name - Freeman Spray
* Description - Code that designates critter movement
* Date Created - 11/11/2022
* Citations - 
* Date Revisions: 11/12/2022

"""
extends CharacterBody2D

# critter physics constants
const ACCELERATION = 25000
const MAX_SPEED = 500
const FRICTION = 500

# Global velocity
var velocity = Vector2.ZERO

var framesTraveled = 0
var direction = true

"""
/*
* @pre Called every frame
* @post x and y velocity of the PlayerCursor element is updated to reflect the current player input (given by pressing WASD)
* @param delta : elapsed time (in seconds) since previous frame. Should be constant across sequential calls
* @return None
*/
"""
func _physics_process(delta):
	framesTraveled = framesTraveled + 1
	if framesTraveled == 300:
		framesTraveled = 0
		direction = not(direction)
	if direction: 
		velocity = velocity.move_toward(Vector2(250,0), FRICTION*delta)
	else:
		velocity = velocity.move_toward(Vector2(-250,0), FRICTION*delta)
	
	set_velocity(velocity)
	move_and_slide()
	velocity = velocity
