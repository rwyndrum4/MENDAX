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
	character.play("idle_" + player_color)
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
	self.position = Global.get_player_pos(player_id)
	var x = self.position.x - last_position.x
	var y = self.position.y - last_position.y
	control_animations(Vector2(x,y).normalized())
	last_position = self.position

"""
/*
* @pre None
* @post updates the character's animations
* @param vel -> Vector2
* @return None
*/
"""
func control_animations(vel):
	#Character moves NorthEast
	if vel.y < 0 and vel.x > 0:
		char_pos.scale.x = -1
		character.play("roll_northwest_" + player_color)
	#Character moves NorthWest
	elif vel.y < 0 and vel.x < 0:
		char_pos.scale.x = 1
		character.play("roll_northwest_" + player_color)
	#Character moves East or SouthEast
	elif vel.x > 0:
		char_pos.scale.x = 1
		character.play("roll_southeast_" + player_color)
	#Character moves West or SoutWest
	elif vel.x < 0:
		char_pos.scale.x = -1
		character.play("roll_southeast_" + player_color)
	#Character moves North
	elif vel.y < 0:
		character.play("roll_north_" + player_color)
	#Character moves South
	elif vel.y > 0:
		character.play("roll_south_" + player_color)
	#Character not moving (idle)
	else:
		character.play("idle_" + player_color)

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
