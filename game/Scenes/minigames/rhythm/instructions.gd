extends Popup

var _timer = 0
signal done_explaining()

var _s1: String = """[center][color=#141414][b]Rhythm Game[/b][/color][/center]
[center]Compete against others to get the highest score[/center]
[center]Larger combo = Larger multiplier[/center]
[center]Keybinds to tap:[/center]"""

var _s2: String = """[center][color=#141414][b]Note Types[/b][/color][/center]"""

var _s3: String = """[center][color=#141414][b]Best of Luck[/b][/color][/center]
[center][color=#03a9fc]Song: The Cannery[/color][/center]
[center][color=#406b57]Artist: Kevin MacLeod[/color][/center]
[center]Game starts in ...[/center]"""

func _ready():
	$hit_bar_ex.show()
	$text_instr.bbcode_text = _s1

func _process(delta):
	_timer += delta
	if _timer > 16:
		emit_signal("done_explaining")
	elif _timer > 12:
		$reg_note_fd.hide()
		$hold_note.hide()
		var extra: String = "[i][b][center]" + str(4 - (int(_timer) % 4)) + "[/center][/b][/i]"
		$text_instr.bbcode_text = _s3 + extra
	elif _timer > 6:
		$hit_bar_ex.hide()
		$text_instr.bbcode_text = _s2
		$reg_note_fd.show()
		$hold_note.show()
