#Inspired by https://github.com/LegionGames/Conductor-Example/blob/master/Scripts/Note.gd

extends Area2D

# Member Variables
onready var text_label = $label_holder/hit_type

const TARGET_Y = 164
const SPAWN_Y = -20
const DIST_TO_TARGET = TARGET_Y - SPAWN_Y

const LANE_ONE_SPAWN = Vector2(420, SPAWN_Y)
const LANE_TWO_SPAWN = Vector2(550, SPAWN_Y)
const LANE_THREE_SPAWN = Vector2(680, SPAWN_Y)
const LANE_FOUR_SPAWN = Vector2(810, SPAWN_Y)

var _speed = 800 #speed of the note
var _hit = false #track whether the note was hit or not

func _ready():
	add_to_group("note")

func _physics_process(delta):
	if not _hit:
		position.y += _speed * delta
		if position.y > 800:
			destroy(0)
			get_parent().reset_combo()
	else:
		$label_holder.position.y -= _speed * delta

func initialize(lane: int, new_speed: int):
	_speed = new_speed
	match lane:
		0: position = LANE_ONE_SPAWN
		1: position = LANE_TWO_SPAWN
		2: position = LANE_THREE_SPAWN
		3: position = LANE_FOUR_SPAWN
		_: 
			printerr("Invalid lane set for a note: " + str(lane))
			return

func destroy(score: int):
	_hit = true
	match score:
		3:
			#print("PERFECT")
			text_label.text = "PERFECT"
			text_label.modulate = Color("#40edb9")
			get_parent().change_score(Save.game_data.username,300)
		2:
			#print("GOOD")
			text_label.text = "GOOD"
			text_label.modulate = Color("#537fed")
			get_parent().change_score(Save.game_data.username,200)
		1:
			#print("OKAY")
			text_label.text = "OKAY"
			text_label.modulate = Color("#dbeb4d")
			get_parent().change_score(Save.game_data.username,100)
		0:
			#print("MISSED")
			text_label.text = "MISSED"
			text_label.modulate = Color("#e03442")
	#Destroy the note when hit
	queue_free()
