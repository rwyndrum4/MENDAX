extends Label

"""
* @pre None
* @post Sets initial money val
* @param None
* @return None
"""
func _ready() -> void:
	rect_position.x = 1180
	text = "Coin: 0"

"""
* @pre Need to know what new money to show user
* @post Sets text of label
* @param new_value (integer of total money owned)
* @return None
"""
func change_total(new_value:int) -> void:
	if len(str(new_value)) == 1:
		rect_position.x = 1180
	elif len(str(new_value)) == 2:
		rect_position.x = 1170
	elif len(str(new_value)) == 3:
		rect_position.x = 1160
	text = "Coin: " + str(new_value)
