"""
* Programmer Name - Freeman Spray, Ben Moeller
* Description - Code that designates player movement for other players
* Date Created - 11/2/2022
* Citations - based on https://www.youtube.com/watch?v=TQKXU7iSWUU
* Date Revisions:
"""
extends KinematicBody2D

# Member Variables
onready var character = $position/animated_sprite
onready var char_pos = $position
var player_color: String = ""
var is_stopped = false
var player_id: int = 0
var last_position:Vector2 = Vector2.ZERO

# Player physics constants
const ACCELERATION = 25000
const MAX_SPEED = 500
const FRICTION = 500

# Global velocity
var velocity = Vector2.ZERO

"""
/*
* @pre Called once when player is initialized
* @post Connects the "textbox_shift" and "openMnu" signals to the player
* @param None
* @return None
*/
"""
func _ready():
	#Connects singal to GlobalSignals, will stop/unstop player when called from "textbBox.gd"
	# warning-ignore:return_value_discarded
	GlobalSignals.connect("textbox_shift",self,"stop_go_player")
	# warning-ignore:return_value_discarded
	GlobalSignals.connect("openMenu",self,"stop_go_player")
	character.play("idle")
	last_position = self.position

"""
/*
* @pre Called every frame
* @post x and y velocity of the PlayerCursor element is updated to reflect the current player input (given by pressing WASD)
* @param delta : elapsed time (in seconds) since previous frame. Should be constant across sequential calls
* @return None
*/
"""
func _physics_process(delta):
	#don't move player if textbox is playing or options are open
	if is_stopped:
		return
	
	# Initialize input velocity
	var input_velocity = Vector2.ZERO
	#Check previous position and check if it has changed since last frame
	input_velocity.x = last_position.x - Global.get_player_pos(player_id).x
	input_velocity.y = last_position.y - Global.get_player_pos(player_id).y 
	input_velocity = input_velocity.normalized()
	
	# Case where no input is given
	if input_velocity == Vector2.ZERO:
		velocity = input_velocity.move_toward(Vector2.ZERO, FRICTION*delta)
	# Case where only vertical input is given
	elif input_velocity.x == 0:
		velocity = input_velocity.move_toward(Vector2(0,input_velocity.y).normalized()*MAX_SPEED, ACCELERATION*delta)
	# Case where only horizontal input is given
	elif input_velocity.y == 0:
		velocity = input_velocity.move_toward(Vector2(input_velocity.x,0).normalized()*MAX_SPEED, ACCELERATION*delta)
	# Case where both horizontal and vertical input is given
	# This ensures diagonal speed is not faster, which is especially significant when sliding against a wall.
	else:
		velocity = input_velocity.move_toward(0.7*input_velocity*MAX_SPEED, ACCELERATION*delta)
	
	# Factor in collisions
	velocity = move_and_slide(velocity)
	control_animations(velocity)

"""
/*
* @pre Called when signal is received from GlobalSignals
* @post updates is_stopped to whatever value is passed in (true = stopped, false = can move)
* @param value -> boolean
* @return None
*/
"""
func stop_go_player(value:bool):
	is_stopped = value

"""
/*
* @pre None
* @post updates the character's animations
* @param vel -> int
* @return None
*/
"""
func control_animations(vel):
	if vel.x > 0:
		char_pos.scale.x = 1
		character.play("roll")
	elif vel.x < 0:
		char_pos.scale.x = -1
		character.play("roll")
	elif vel.y != 0:
		character.play("roll")
	else:
		character.play("idle")

"""
/*
* @pre None
* @post sets player id to what was passed int
* @param id_in -> String
* @return None
*/
"""
func set_player_id(id_in:int):
	player_id = id_in

"""
/*
* @pre None
* @post sets player color to what was passed int
* @param player_num -> int
* @return None
*/
"""
func set_color(player_num:int):
	match player_num:
		1:
			player_color = "blue"
		2:
			player_color = "red"
		3:
			player_color = "green"
		4:
			player_color = "orange"
		_:
			player_color = "blue"
