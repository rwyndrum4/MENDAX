extends Label

var my_text = "Full\nCombo!!!"

func start_ani(full_combo:bool):
	if not full_combo:
		my_text = "Song\nComplete!!"
	show()
	text = my_text
	$Tween.interpolate_property(
		self,
		"percent_visible",
		0.0,
		1.0,
		2.0,
		Tween.TRANS_LINEAR,
		Tween.EASE_IN_OUT
	)
	$Tween.start()
