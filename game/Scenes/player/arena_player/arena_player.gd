"""
* Programmer Name - Freeman Spray, Ben Moeller
* Description - Code that designates player movement for other players
* Date Created - 11/2/2022
* Citations - based on https://www.youtube.com/watch?v=TQKXU7iSWUU
* Date Revisions:
"""
extends CharacterBody2D

# Member Variables
@onready var character = $position/animated_sprite
@onready var char_pos = $position
@onready var healthbar = $ProgressBar
@onready var p_sword = $Sword
@onready var _pivot = $Sword/pivot
@onready var _anim_player = $Sword/AnimationPlayer
var _global_sword_dir = "right"
var player_color: String = ""
var is_stopped = false
var player_id: int = 0

# Player physics constants
const ACCELERATION = 25000
const MAX_SPEED = 500
const FRICTION = 500

# Global velocity
var velocity = Vector2.ZERO

# Signals
signal player_died(p_id) #fires when player health goes >= 0

"""
/*
* @pre Called once when player is initialized
* @post Connects the "textbox_shift" and "openMnu" signals to the playerw
* @param None
* @return None
*/
"""
func _ready():
	healthbar.value = 100
	character.play("idle_" + player_color)

"""
/*
* @pre Called every frame
* @post x and y velocity of the PlayerCursor element is updated to reflect the current player input (given by pressing WASD)
* @param delta : elapsed time (in seconds) since previous frame. Should be constant across sequential calls
* @return None
*/
"""
func _physics_process(_delta):
	self.position = Global.get_player_pos(player_id)
	control_animations(Global.get_player_input_vec(player_id))
	#Control sword position
	if _global_sword_dir == "right":
		p_sword.position = (self.position/40) + Vector2(30,-60)
	elif _global_sword_dir == "left":
		p_sword.position = (self.position/40) + Vector2(-60,-60)

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
		_global_sword_dir = "right"
		_pivot.scale.x = 1
		char_pos.scale.x = -1
		character.play("roll_northwest_" + player_color)
	#Character moves NorthWest
	elif vel.y < 0 and vel.x < 0:
		_global_sword_dir = "left"
		_pivot.scale.x = -1
		char_pos.scale.x = 1
		character.play("roll_northwest_" + player_color)
	#Character moves East or SouthEast
	elif vel.x > 0:
		_global_sword_dir = "right"
		_pivot.scale.x = 1
		char_pos.scale.x = 1
		character.play("roll_southeast_" + player_color)
	#Character moves West or SoutWest
	elif vel.x < 0:
		_global_sword_dir = "left"
		_pivot.scale.x = -1
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
func take_damage(new_health) -> void:
	healthbar.value = new_health
	if healthbar.value <= 0:
		emit_signal("player_died", player_id)
		queue_free()

"""
/*
* @pre called when server says a player has swung their sword
* @post plays the correct animation for the player's sword
* @param sword_direction -> String (direction player should swing)
* @return None
*/
"""
func swing_sword(sword_direction: String):
	_global_sword_dir = sword_direction
	if sword_direction == "right":
		if _global_sword_dir != "right":
			_pivot.scale.x = 1
			_anim_player.play("RESET")
			await _anim_player.animation_finished
		_anim_player.play("slash")
		await _anim_player.animation_finished
		_anim_player.play("slash_rev")
		await _anim_player.animation_finished
	elif sword_direction == "left":
		if _global_sword_dir != "left":
			_pivot.scale.x = -1
			_anim_player.play("RESET2")
			await _anim_player.animation_finished
		_anim_player.play("slashLeft")
		await _anim_player.animation_finished

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
