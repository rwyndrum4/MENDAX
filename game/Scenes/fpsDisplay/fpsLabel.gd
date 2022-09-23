#Based on tutorial from https://www.youtube.com/watch?v=cQkEPej_gRU
extends Label

func _ready():
	GlobalSettings.connect("fpsDisplayed", self, "_on_fps_displayed")
	
func _process(delta):
	text = "FPS: %s" % [Engine.get_frames_per_second()]

func _on_fps_displayed(value):
	visible = value
