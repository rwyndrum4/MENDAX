extends RichTextLabel

"""
/*
* @pre None
* @post Balance text is updated to the player's money
* @param _delta but is ignored
* @return None
*/
"""
func _process(_delta):
	set_text("Balance: "+str(Global.money)) #sets the balance text for store
