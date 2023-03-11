#Inspired by https://github.com/LegionGames/Conductor-Example/blob/master/Scripts/Note.gd

extends Area2D

# Member Variables
@onready var hold_zone = $hold_pivot_node/hold_zone
@onready var first_label_text = $first_label/hit_type
@onready var second_label_text = $second_label/hit_type
@onready var second_sprite = $second_sprite
@onready var second_collider = $second_collider
var _current_label = null

const MODULATE_VALUE = 8
const SPAWN_Y = -20
const ANGLE_HIGH = 130
const ANGLE_LOW = 30
const MAX_HOLD_ZONE_HEIGHT = 400
const MIN_HOLD_ZONE_HEIGHT = 300
const LANE_ONE_SPAWN = Vector2(503, SPAWN_Y)
const LANE_TWO_SPAWN = Vector2(568, SPAWN_Y)
const LANE_THREE_SPAWN = Vector2(660, SPAWN_Y)
const LANE_FOUR_SPAWN = Vector2(725, SPAWN_Y)

const LABEL_SPEED = 650 #Speed of the label saying what type of score a note was
var _hold_height = 0 #keep track of how high the hold zone should be
var _right_key = "" #variable to track what key to hold down
var _speed: Vector2 = Vector2(0,800) #speed of the note
var _first_hit = false #track whether the first note was hit or not
var _second_hit = false #track whether the secpnd note was hit or not
var _in_hold_phase = false #track if in the holding phase

"""
/*
* @pre Called when the object is added to scene
* @post sets randome seed and finished setting up object
* @param None
* @return None
*/
"""
func _ready():
	assert(_hold_height != 0) #,"ERROR: Hold note height not set")
	$slide_sound.volume_db = 8
	$final_hit_sound.volume_db = -6
	randomize()
	finish_object(_hold_height)
	add_to_group("note")

"""
/*
* @pre None
* @post returns the node type
* @param None
* @return String
*/
"""
func get_type() -> String:
	return "hold_note"

"""
/*
* @pre None
* @post sets the height of the node (for if you don't want it to be random)
* @param height_in -> int (height to set of hold note)
* @return None
*/
"""
func set_height(height_in: int):
	_hold_height = height_in

"""
/*
* @pre None
* @post increases the modulate of the hold zone so user knows they are holding it down
* @param None
* @return None
*/
"""
func brighten_hold_zone():
	if _in_hold_phase:
		$slide_sound.play()
		hold_zone.modulate.a8 = 180
		$first_sprite.modulate.a8 = 200
		second_sprite.modulate.a8 = 200

"""
/*
* @pre None
* @post called when user lets go of the hold zone (goes back to normal)
* @param None
* @return None
*/
"""
func reset_hold_zone():
	$slide_sound.stop()
	if _in_hold_phase:
		hold_zone.modulate.a8 = 75
		second_sprite.modulate.a8 = 75

"""
/*
* @pre Called for every frame of the game
* @post moves the note object and feedback text
* @param None
* @return None
*/
"""
func _physics_process(delta):
	if not (_first_hit and _second_hit):
		position += _speed * delta
		if position.y > 3000:
			get_parent().increment_counters(0)
			if not _second_hit:
				destroy(0,true)
	else:
		_current_label.position.y -= LABEL_SPEED * delta
		_current_label.modulate.a8 -= MODULATE_VALUE

"""
/*
* @pre Called before ready function even fires
* @post sets position, speed, and key that is being held down
* @param lane -> int (lane to spawn in), new_speed -> int (y axis speed),
* @return None
*/
"""
func initialize(lane: int, new_speed: int):
	match lane:
		0: 
			position = LANE_ONE_SPAWN
			_speed = Vector2(-ANGLE_HIGH, new_speed)
			_right_key = "blue_rhythm"
		1: 
			position = LANE_TWO_SPAWN
			_speed = Vector2(-ANGLE_LOW, new_speed)
			_right_key = "green_rhythm"
		2: 
			position = LANE_THREE_SPAWN
			_speed = Vector2(ANGLE_LOW, new_speed)
			_right_key = "orange_rhythm"
		3: 
			position = LANE_FOUR_SPAWN
			_speed = Vector2(ANGLE_HIGH, new_speed)
			_right_key = "red_rhythm"
		_: 
			printerr("Invalid lane set for a note: " + str(lane))
			return

"""
/*
* @pre Called inside of the ready function
* @post finished setting angles, heights, and widths of various objects
* @param zone_height -> int (how high the hold note should be)
* @return None
*/
"""
func finish_object(zone_height: int):
	hold_zone.size.y = zone_height
	var zone_degree = $hold_pivot_node.rotation_degrees + get_angle()
	$hold_pivot_node.rotation_degrees = zone_degree
	var x_result = calc_change(zone_degree, zone_height)
	second_sprite.position.x = x_result
	second_sprite.position.y = -zone_height
	second_collider.position.x = x_result
	second_collider.position.y = -zone_height
	$second_label.position.x = x_result
	$second_label.position.y -= zone_height

"""
/*
* @pre Called when note wants to be destroyed (needs to be called twice )
* @post performs various tasks depending on if it is the first or second time called
* @param score -> int (score type, perfect good etc)
*		 note_fully_missed -> bool (optional: only used when note is fully missed)
* @return None
*/
"""
func destroy(score: int, note_fully_missed = false):
	var text_label
	var delete_node = false
	#Change parameters based on if it is on the first or second note
	if not _first_hit:
		text_label = first_label_text
		_current_label = $first_label
		_first_hit = true
		_in_hold_phase = true
		$first_collider.queue_free()
	else:
		if score > 0:
			$final_hit_sound.play()
		text_label = second_label_text
		_current_label = $second_label
		_second_hit = true
		_in_hold_phase = false
		$second_collider.queue_free()
		hold_zone.queue_free()
		$first_sprite.queue_free()
		$second_sprite.queue_free()
		delete_node = true
	#Give a score for the hit
	match score:
		3:
			text_label.text = "PERFECT"
			text_label.modulate = Color("#40edb9")
			get_parent().change_score(Save.game_data.username,300)
		2:
			text_label.text = "GOOD"
			text_label.modulate = Color("#537fed")
			get_parent().change_score(Save.game_data.username,200)
		1:
			text_label.text = "OKAY"
			text_label.modulate = Color("#dbeb4d")
			get_parent().change_score(Save.game_data.username,100)
		0:
			text_label.text = "MISSED"
			text_label.modulate = Color("#e03442")
	#covers the case if player misses the note entirely
	if note_fully_missed or delete_node:
		_delete_node()

"""
/*
* @pre None
* @post deletes note object
* @param None
* @return None
*/
"""
func _delete_node():
	if _second_hit:
		await $final_hit_sound.finished
	queue_free()

"""
/*
* @pre None
* @post returns the angle that the hold_note should be angled at
* @param None
* @return int
*/
"""
func get_angle() -> int:
	var s = _speed.x
	if s == ANGLE_HIGH:
		return -7
	elif s == ANGLE_LOW:
		return -2
	elif s == -ANGLE_HIGH:
		return 7
	elif s == -ANGLE_LOW:
		return 2
	else:
		return 0

"""
/*
* @pre None
* @post returns the x distance that the second note should move so that it
* can align where the new final destination should be. This has to be done 
* because the distance changes when angle is adjusted
* @param deg -> int (degree that the not changed to), 
* height -> int (height that the note has)
* @return int
*/
"""
func calc_change(deg, height) -> int:
	return height * sin(PI * 2 * deg/360)
