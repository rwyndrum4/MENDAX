extends Sprite

var _final_pos:Vector2
signal boulder_done()

func _ready():
	scale = Vector2(4,4)

func _physics_process(_delta):
	position.y += 10
	if position == _final_pos:
		emit_signal("boulder_done")
		queue_free()

func set_final_pos(f_pos:Vector2):
	_final_pos = f_pos
