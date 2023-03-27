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
	3/25/2023 - Added powerups
"""
extends KinematicBody2D

# Member Variables
onready var character = $position/animated_sprite
onready var char_pos = $position
onready var healthbar = $ProgressBar
onready var isInverted = false
onready var shield = $Shield
onready var current_powerup = "default"
var speed_ticks
var speed_wait_period
var luck_steps
var reach_light_growing
var is_stopped = false
var player_color:String = ""
var once

# Player physics constants
var ACCELERATION = 25000
var MAX_SPEED = 500
var FRICTION = 500

# Global velocity
var velocity = Vector2.ZERO

var is_walk: bool = false
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
	# if server wasnt' connected
	if player_color == "":
		player_color = "blue"
		
	#Initially have character idle
	character.play("idle_" + player_color)
	once = true
	
	# Initialize powerup from menu:
	toggle_powerup(Global.powerup)
	
"""
/*
* @pre An input of any sort
* @post Input is handled
* @param Takes in input as an event
* @return none
*/
"""
func _input(_ev):
	if Input.is_action_just_pressed("toggle_powerup_debug", false):
		toggle_powerup(null)
		

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
	# Luck implementation
	if (abs(input_velocity.x) > 0 or abs(input_velocity.y) > 0) and current_powerup == "luck":
		luck_steps+=1
		if luck_steps == 777:
			luck_steps = 0
			var player_id = 1
			if ServerConnection.match_exists() and ServerConnection.get_server_status():
				player_id = ServerConnection._player_num
			var player_name = Global.get_player_name(player_id)
			GameLoot.add_to_coin(player_id, 1)
			if player_name == Save.game_data.username:
				var total_coin = GameLoot.get_coin_val(player_id)
				get_parent().get_parent().change_money(total_coin)
				PlayerInventory.add_item("Coin", 1)
			
	
"""
/*
* @pre Called every frame
* @post continual processes are handled (all related to powerups)
* @param _delta : elapsed time (in seconds) since previous frame. Remove _ to use.
* @return None
*/
"""
func _process(_delta):
	if current_powerup == "speed":
		speed_ticks+=1
		if speed_ticks == 8:
			$PowerupIndicator.energy = 2
			var rng = RandomNumberGenerator.new()
			rng.randomize()
			speed_wait_period = rng.randi_range(0, 80)
		elif speed_ticks == 20 + speed_wait_period:
			$PowerupIndicator.energy = 1
			speed_ticks = 0
	if current_powerup == "reach":
		if reach_light_growing:
			$PowerupIndicator.texture_scale = $PowerupIndicator.texture_scale + 0.004
			if $PowerupIndicator.texture_scale >= 1.0:
				reach_light_growing = false
		else:
			$PowerupIndicator.texture_scale = $PowerupIndicator.texture_scale - 0.004
			if $PowerupIndicator.texture_scale <= 0.9:
				reach_light_growing = true
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
		is_walk = true
	#Character moves NorthWest
	elif vel.y < 0 and vel.x < 0:
		char_pos.scale.x = 1
		character.play("roll_northwest_" + player_color)
		is_walk = true
	#Character moves East or SouthEast
	elif vel.x > 0:
		char_pos.scale.x = 1
		character.play("roll_southeast_" + player_color)
		is_walk = true
	#Character moves West or SoutWest
	elif vel.x < 0:
		char_pos.scale.x = -1
		character.play("roll_southeast_" + player_color)
		is_walk = true
	#Character moves North
	elif vel.y < 0:
		character.play("roll_north_" + player_color)
		is_walk = true
	#Character moves South
	elif vel.y > 0:
		character.play("roll_south_" + player_color)
		is_walk = true
	#Character not moving (idle)
	else:
		character.play("idle_" + player_color)
		is_walk = false
	walkCheck()

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

"""
/*
* @pre None
* @post Removes the effects of the current powerup and applies effects of a new powerup ()
* @param powerup -> 
* @return None
*/
"""
func toggle_powerup(powerup):
	# If no powerup argument is supplied, assume we want to toggle to next powerup.
	# Should only occur in testing
	if powerup == null:
		if current_powerup == "default":
			powerup = "speed"
		if current_powerup == "speed":
			powerup = "strength"
		if current_powerup == "strength":
			powerup = "endurance"
		if current_powerup == "endurance":
			powerup = "luck"
		if current_powerup == "luck":
			powerup = "sus"
		if current_powerup == "sus":
			powerup = "reach"
		if current_powerup == "reach":
			powerup = "glow"
		if current_powerup == "glow":
			powerup = "default"
	# Remove effects of current powerup
	# Don't need to worry about "default"  or "luck" case here as these rely only on the current_powerup field being set
	if current_powerup == "speed":
		ACCELERATION = 25000
		MAX_SPEED = 500
	elif current_powerup == "strength":
		# reduce damage back to normal
		GlobalSignals.emit_signal("strength", -50)
	if current_powerup == "endurance":
		# reduce max HP back to normal
		healthbar.max_value = 100
	elif current_powerup == "sus":
		set_color(ServerConnection._player_num)
	elif current_powerup == "reach":
		# change hurtbox back to normal size
		GlobalSignals.emit_signal("reach", "deactivate")
	elif current_powerup == "glow":
		# show torch (NOTE: need to make so this resumes torch progress)
		$light.show()
		# hide glow effect
		$PowerupIndicator.texture_scale = 1
	# Set effects of new powerup
	if powerup == "default":
		$PowerupIndicator.hide()
		current_powerup = "default"
	elif powerup == "speed":
		ACCELERATION = 40000
		MAX_SPEED = 750
		speed_ticks = 0
		speed_wait_period = 0
		$PowerupIndicator.energy = 1
		$PowerupIndicator.show()
		$PowerupIndicator.color = "98f26b"
		current_powerup = "speed"
	elif powerup == "strength":
		# increase sword damage
		GlobalSignals.emit_signal("strength", 50)
		$PowerupIndicator.show()
		$PowerupIndicator.color = "bc2b2b"
		current_powerup = "strength"
	elif powerup == "endurance":
		# increase max HP and heal for same amount
		healthbar.max_value = 150
		healthbar.value+=50
		$PowerupIndicator.show()
		$PowerupIndicator.color = "2b2ebc"
		current_powerup = "endurance"
	elif powerup == "luck":
		# add luck effect that grants coin for travel time
		luck_steps = 0
		$PowerupIndicator.show()
		$PowerupIndicator.color = "c7bc11"
		current_powerup = "luck"
	elif powerup == "sus":
		# change sprite color
		var rng = RandomNumberGenerator.new()
		rng.randomize()
		var colors
		if player_color == "blue":
			colors = ["red", "green", "orange"]
		if player_color == "red":
			colors = ["blue", "green", "orange"]
		if player_color == "green":
			colors = ["blue", "red", "orange"]
		if player_color == "orange":
			colors = ["blue", "red", "green"]
		var rand_index = rng.randi_range(0,2)
		player_color = colors[rand_index]
		$PowerupIndicator.hide()
		current_powerup = "sus"
	elif powerup == "reach":
		# expand size of hurtbox
		GlobalSignals.emit_signal("reach", "activate")
		reach_light_growing = true
		$PowerupIndicator.texture_scale = 0.9
		$PowerupIndicator.show()
		$PowerupIndicator.color = "f09653"
		current_powerup = "reach"
	elif powerup == "glow":
		# Hide torch (NOTE: need to make so this resumes torch progress)
		$light.hide()
		# show glow effect
		$PowerupIndicator.texture_scale = 4
		$PowerupIndicator.show()
		$PowerupIndicator.color = "37e5dd"
		current_powerup = "glow"		
		
func walkCheck():
	var currently = $walk.is_playing()
	if is_walk:
		if currently:
			pass
		else:
			$walk.playing = true
	else:
		$walk.playing = false
