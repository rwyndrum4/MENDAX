"""
* Programmer Name - Freeman Spray, Ben Moeller
* Description - Code that designates player movement
* Date Created - 10/1/2022
* Citations - based on https://www.youtube.com/watch?v=TQKXU7iSWUU
* Date Revisions:
	10/2/2022 - Improved movement to feel more natural
	10/14/2022 - Added signals to stop player when in options or textbox scene
	10/27/2022 - Added character animation
	11/28/2022 - Added death handling
"""
extends KinematicBody2D

# Member Variables
onready var character = $position/animated_sprite
onready var char_pos = $position
onready var healthbar = $ProgressBar
var is_stopped = false
var player_color:String = ""

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
	# if server wasnt' connected
	if player_color == "":
		player_color = "blue"
	#Initially have character idle
	character.play("idle_" + player_color)
	

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
		control_animations(Vector2.ZERO) #play idle animation
		return
	
	# Initialize input velocity
	var input_velocity = Vector2.ZERO
	input_velocity.x = Input.get_axis("ui_left", "ui_right")
	input_velocity.y = Input.get_axis("ui_up", "ui_down") 
	
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
	
	#Send current player position to server if server and match is up
	if ServerConnection.get_server_status() and ServerConnection.match_exists():
		#Send position and input to other players (if has changed!)
		ServerConnection.send_position_update(position)
		ServerConnection.send_input_update(velocity.normalized())
		#Store new position and input in order to check if has changed next time (if has changed!)
		Global._player_positions_updated(ServerConnection._player_num, self.position)
		Global._player_input_updated(ServerConnection._player_num, velocity.normalized())
	# Factor in collisions
	velocity = move_and_slide(velocity)
	#Animate character
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
* @param vel -> Vector2
* @return None
*/
"""
func control_animations(vel:Vector2):
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
* @pre Called by when it detects a "hit" from a hitbox
* @post Mob takes damage and is reflected by the healthbar
* @param Takes in a damage value
* @return None
*/
"""
func take_damage(amount: int) -> void:
	var new_health = healthbar.value - amount
	ServerConnection.send_arena_player_health(new_health)
	healthbar.value = new_health
	if healthbar.value == 0:
		get_parent()._player_dead = true
		_game_over()
		queue_free()

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

"""
/*
* @pre Called when the player's health bar is reduced to 0
* @post scene transitions to game over screen
* @param Takes a playerID value (not used)
* @return None
*/
"""	
func _game_over():
		Global.state = Global.scenes.GAMEOVER
