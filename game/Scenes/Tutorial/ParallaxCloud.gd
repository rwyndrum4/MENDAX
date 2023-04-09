extends ParallaxLayer

var CLOUD_SPEED = -2.5


func _process(delta):
	self.motion_offset.x += CLOUD_SPEED * delta
