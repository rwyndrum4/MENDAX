extends ParallaxLayer

var CLOUD_SPEED = -2.5
var rng
var randomthing = RandomNumberGenerator.new()

func _ready():
	randomize()
	rng = randi() % 2
	randomthing.randomize()
	CLOUD_SPEED = randomthing.randf_range(-8,-2)

func _process(delta):
	if rng == 0:
		self.motion_offset.x += CLOUD_SPEED * delta
	if rng == 1:
		self.motion_offset.x -= CLOUD_SPEED * delta
