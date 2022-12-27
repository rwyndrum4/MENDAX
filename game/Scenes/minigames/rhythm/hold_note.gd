#Inspired by https://github.com/LegionGames/Conductor-Example/blob/master/Scripts/Note.gd

extends Area2D

# Member Variables
onready var hold_zone = $hold_pivot_node/hold_zone
onready var first_label_text = $first_label/hit_type
onready var second_label_text = $second_label/hit_type
onready var second_sprite = $second_sprite
onready var second_collider = $second_collider
var _current_label = null

const MODULATE_VALUE = 8
const SPAWN_Y = -20
const ANGLE_HIGH = 130
const ANGLE_LOW = 30
const MAX_HOLD_ZONE_HEIGHT = 400
const MIN_HOLD_ZONE_HEIGHT = 300
const LANE_ONE_SPAWN = Vector2(500, SPAWN_Y)
const LANE_TWO_SPAWN = Vector2(570, SPAWN_Y)
const LANE_THREE_SPAWN = Vector2(660, SPAWN_Y)
const LANE_FOUR_SPAWN = Vector2(730, SPAWN_Y)

const LABEL_SPEED = 650 #Speed of the label saying what type of score a note was
var _hold_height = 0 #keep track of how high the hold zone should be
var _right_key = "" #variable to track what key to hold down
var _speed: Vector2 = Vector2(0,800) #speed of the note
var _first_hit = false #track whether the first note was hit or not
var _second_hit = false #track whether the secpnd note was hit or not
var _in_hold_phase = false #track if in the holding phase

func _ready():
	randomize()
	_hold_height = randi() % MAX_HOLD_ZONE_HEIGHT + MIN_HOLD_ZONE_HEIGHT
	finish_object(_hold_height)
	add_to_group("note")

func get_type() -> String:
	return "hold_note"

func _physics_process(delta):
	if not (_first_hit and _second_hit):
		position += _speed * delta
		if position.y > 1400:
			get_parent().increment_counters(0)
			destroy(0)
	else:
		_current_label.position.y -= LABEL_SPEED * delta
		_current_label.modulate.a8 -= MODULATE_VALUE

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

func finish_object(zone_height: int):
	hold_zone.rect_size.y = zone_height
	var zone_degree = $hold_pivot_node.rotation_degrees + get_angle()
	$hold_pivot_node.rotation_degrees = zone_degree
	var x_result = calc_change(zone_degree, zone_height)
	second_sprite.position.x = x_result
	second_sprite.position.y = -zone_height
	second_collider.position.x = x_result
	second_collider.position.y = -zone_height
	$second_label.position.x = x_result
	$second_label.position.y -= zone_height

func destroy(score: int):
	var text_label
	#Change parameters based on if it is on the first or second note
	if not _first_hit:
		text_label = first_label_text
		_current_label = $first_label
		_first_hit = true
		_in_hold_phase = true
		$first_collider.queue_free()
	else:
		text_label = second_label_text
		_current_label = $second_label
		_second_hit = true
		_in_hold_phase = false
		$second_collider.queue_free()
		hold_zone.queue_free()
		$first_sprite.queue_free()
		$second_sprite.queue_free()
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
	#Destroy the note when hit based on a timer
	var destroy_timer: Timer = Timer.new()
	destroy_timer.one_shot = true
	destroy_timer.wait_time = 3
	add_child(destroy_timer)
	destroy_timer.start()
	# warning-ignore: return_value_discarded
	destroy_timer.connect("timeout", self, "_delete_node", [destroy_timer])

func _delete_node(timer_var: Timer):
	timer_var.queue_free()
	queue_free()

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

func calc_change(deg, height) -> int:
	return height * sin(PI * 2 * deg/360)
