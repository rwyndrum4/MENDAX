extends Label

var my_text = "Full Combo!!!"

func start_ani():
	show()
	for l in my_text:
		if l == " ":
			l = "\n"
		text += l
		var t = Timer.new()
		add_child(t)
		t.wait_time = 0.15
		t.one_shot = true
		t.start()
		yield(t, "timeout")
		t.queue_free()
