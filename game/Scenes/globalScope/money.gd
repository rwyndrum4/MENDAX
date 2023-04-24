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
	var x = len(str(new_value))
	rect_position.x = 1190 - (10 * x)
	text = "Coin: " + str(new_value)
