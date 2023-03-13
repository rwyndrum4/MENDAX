extends Popup

var _colors: Array = ["#3679e3", "#e34d36", "#36e381", "#e3a436"]

func add_results(playersRes:Dictionary):
	var res_str: String = "[center][color=#202124]Results[/color][/center]\n"
	var ctr: int = 0
	for p_name in playersRes.keys():
		res_str += "[center][color="
		res_str += _colors[ctr] + "]"
		var status = playersRes[p_name]
		res_str += p_name + ": " + status + " -> "
		res_str += "+ 20 coin" if status == "Lived" else "No rewards"
		res_str += "[/color][/center]\n"
		ctr += 1
	$textResults.bbcode_enabled = true
	$textResults.bbcode_text = res_str
