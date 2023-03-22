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
	2/14/2023  - Added inverted controls option
"""
extends KinematicBody2D

#Objects
onready var character = $position/animated_sprite
onready var char_pos = $position
onready var healthbar = $ProgressBar
onready var shield = $Shield

# Member Variables
var isInverted = false
var is_stopped = false
var player_color:String = ""
var once
# Player physics constants
const FRICTION = 500
var ACCELERATION = 25000
var MAX_SPEED = 500
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
	#adding area 2d to this group, can be checked in area2d signals
	#example in littleGuy.gd
	$MyHurtBox.add_to_group("player")
	#Connects singal to GlobalSignals, will stop/unstop player when called from "textbBox.gd"
	# warning-ignore:return_value_discarded
	GlobalSignals.connect("textbox_shift",self,"stop_go_player")
	# warning-ignore:return_value_discarded
	GlobalSignals.connect("openMenu",self,"stop_go_player")
	# if server wasn't connected
	if player_color == "":
		player_color = "blue"
	#Initially have character idle
	character.play("idle_" + player_color)
	once = true
	if ServerConnection.match_exists() and ServerConnection.get_server_status():
		#timer that will go off roughly 15 times per second
		var send_pos_tmr = Timer.new()
		send_pos_tmr.one_shot = false
		send_pos_tmr.wait_time = 0.05
		add_child(send_pos_tmr)
		send_pos_tmr.start()
		send_pos_tmr.connect("timeout", self, "_send_server_update")

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
	# Inverted controls if invert is active <------------------------------------------------BEN I CHANGED THIS
	if isInverted == true:
		input_velocity.x = Input.get_axis("ui_right", "ui_left")
		input_velocity.y = Input.get_axis("ui_down", "ui_up") 
		if once:
			once = false
			var wait_for_start: Timer = Timer.new()
			add_child(wait_for_start)
			wait_for_start.wait_time = 5
			wait_for_start.one_shot = true
			wait_for_start.start()
			# warning-ignore:return_value_discarded
			wait_for_start.connect("timeout",self, "_invert_off",[wait_for_start])
	else:
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
	# Factor in collisions
	velocity = move_and_slide(velocity)
	#Animate character
	control_animations(velocity)

"""
* @pre Called 15 times per second
* @post Sends the current player position to the server (and input vector if changed)
* @param None (uses global vars: velocity and inherit position)
* @return None
"""
func _send_server_update():
	#Send position change to server (only if changed, logic in function)
	ServerConnection.send_position_update(position)
	#Sends input vector to server (only if changed, logic in function)
	ServerConnection.send_input_update(velocity.normalized())
	#Store new position and input in order to check if has changed next time (if has changed!)
	Global._player_positions_updated(ServerConnection._player_num, self.position)
	Global._player_input_updated(ServerConnection._player_num, velocity.normalized())

"""
/*
* @pre Called in arena game, when player hit by littleGuy
* @post slows the player's speed by 1/2
* @param None
* @return None
*/
"""
func temporary_slow():
	MAX_SPEED /= 2
	var tmr = Timer.new()
	tmr.one_shot = true
	tmr.wait_time = 3
	add_child(tmr)
	tmr.connect("timeout",self,"_tmr_unslow_player", [tmr])
	tmr.start()

#Function that goes off based on code above
func _tmr_unslow_player(tmr:Timer):
	tmr.queue_free()
	MAX_SPEED *= 2

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
	if shield.isUp():
		shield.takeDamage()
	else:
		var new_health = healthbar.value - amount
		Global.player_health[str(1)]=new_health
		ServerConnection.send_arena_player_health(new_health)
		healthbar.value = new_health
		if healthbar.value <= 0 and Global.state == Global.scenes.ARENA_MINIGAME: #should fix it
			get_parent()._player_dead = true
			get_parent().spectate_mode()
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

func _invert_off(timer):
	timer.queue_free()
	isInverted = false
	once = true
