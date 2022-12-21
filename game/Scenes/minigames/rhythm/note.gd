#Inspired by https://github.com/LegionGames/Conductor-Example/blob/master/Scripts/Note.gd

extends Area2D

# Member Variables
onready var text_label = $label_holder/hit_type

const TARGET_Y = 164
const SPAWN_Y = -16
const DIST_TO_TARGET = TARGET_Y - SPAWN_Y

const LANE_ONE_SPAWN = Vector2(120, SPAWN_Y)
const LANE_TWO_SPAWN = Vector2(160, SPAWN_Y)
const LANE_THREE_SPAWN = Vector2(200, SPAWN_Y)
const LANE_FOUR_SPAWN = Vector2(240, SPAWN_Y)

var _speed = 0 #speed of the note
var _hit = false #track whether the note was hit or not

func _physics_process(delta):
	if not _hit:
		position.y += _speed * delta
		if position.y > 200:
			destroy(0)
			get_parent().reset_combo()
	else:
		$label_holder.position.y -= _speed * delta

func initialize(lane: int):
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
			text_label.text = "PERFECT"
			text_label.modulate = Color("#40edb9")
			get_parent().add_score(Save.game_data.username,300)
		2:
			text_label.text = "GOOD"
			text_label.modulate = Color("#537fed")
			get_parent().add_score(Save.game_data.username,200)
		1:
			text_label.text = "OKAY"
			text_label.modulate = Color("#dbeb4d")
			get_parent().add_score(Save.game_data.username,100)
		0:
			text_label.text = "MISSED"
			text_label.modulate = Color("#e03442")
	#Destroy the note when hit
	queue_free()
