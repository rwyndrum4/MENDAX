extends Popup

onready var score_tab = $Scores

func _ready():
	set_scores()

func set_scores():
	var ctr = 1
	for score in Save.game_data.high_scores:
		var txtLbl = getFont(ctr)
		txtLbl.text = str(ctr) + ": " + str(score)
		score_tab.add_child(txtLbl)
		ctr += 1
	
func getFont(idx: int) -> Label:
	var colors = [Color.blue, Color.red, Color.green, Color.orange, Color.plum]
	var silver_font = DynamicFont.new()
	silver_font.font_data = load("res://Assets/Silver.ttf")
	silver_font.size = 60
	silver_font.outline_size = 4
	silver_font.outline_color = colors[idx-1]
	silver_font.use_filter = true
	var score_label: Label = Label.new()
	score_label.add_font_override("font",silver_font)
	score_label.add_color_override("font_color",Color.white)
	return score_label
