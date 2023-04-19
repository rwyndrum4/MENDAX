extends Sprite

const COLORS = [Color.cyan, Color.red, Color.green, Color.orange]

func _ready():
	$p_indicator.set_frame_color(COLORS[0])
	#If not single player, change color to match the player
	if ServerConnection.match_exists() and ServerConnection.get_server_status():
		var color_num = ServerConnection._player_num - 1 #player nums are 1 - 4, sub 1 for array
		if color_num in range(0,4): #check in case above goes wrong
			$p_indicator.set_frame_color(COLORS[color_num])
	# warning-ignore:return_value_discarded
	GlobalSignals.connect("player_moved", self, "update_map") #catch signals of main player moving
	var blink_tmr = Timer.new()
	blink_tmr.wait_time = 0.5
	blink_tmr.one_shot = false
	add_child(blink_tmr)
	blink_tmr.connect("timeout", self, "blink")
	blink_tmr.start() #when timer goes off, idicator goes on/off

"""
* Pre: Signal received from GlobalSignals
* Post: Change position of the indicator
* Return: None
"""
func update_map(p_pos:Vector2):
	$p_indicator.rect_position = get_area(p_pos)

"""
* Pre: Area has been passed to this script
* Post: Makes the indicator on minimap blink
* Return: Vector2 of area to place indicator
"""
func get_area(pos:Vector2) -> Vector2:
	var result = Vector2.ZERO
	if pos.x > 1450:
		result = Vector2(25,-3.2) #far right
	elif pos.x > -575 and pos.y < 600:
		result = Vector2(12,-13.6) #above entrance
	elif pos.x > -575 and pos.y > 600:
		result = Vector2(13.2, -2.4) #below entrance
	elif pos.x > -6300:
		result = Vector2(-2,-4) #steam corridor
	elif pos.x > -8060 and pos.y < 4870:
		result = Vector2(-15.8, -3.4) #left of steam corridor but above
	elif pos.x > -8060 and pos.y > 4870:
		result = Vector2(-15, 11.2) #left of steam corridor but below
	else:
		result = Vector2(-28.4, 10) #far left side
	return result

"""
* Pre: Player in cave and alive
* Post: Makes the indicator on minimap blink
* Return: None
"""
func blink():
	$p_indicator.visible = not $p_indicator.visible
