#Inspired by https://github.com/LegionGames/Conductor-Example/blob/master/Scripts/Note.gd

extends Area2D

# Member Variables
onready var text_label = $label_holder/hit_type

const MODULATE_VALUE = 8
const SPAWN_Y = -20
const LANE_ONE_SPAWN = Vector2(420, SPAWN_Y)
const LANE_TWO_SPAWN = Vector2(550, SPAWN_Y)
const LANE_THREE_SPAWN = Vector2(680, SPAWN_Y)
const LANE_FOUR_SPAWN = Vector2(810, SPAWN_Y)

const LABEL_SPEED = 650 #Speed of the label saying what type of score a note was
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
		$label_holder.position.y -= LABEL_SPEED * delta
		$label_holder.modulate.a8 -= MODULATE_VALUE

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
	$Sprite.queue_free()
	$CollisionShape2D.queue_free()
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
