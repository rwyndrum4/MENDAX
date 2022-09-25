"""
* Programmer Name - Jason Truong
* Description - Controls the balance text in StoreVars.tscn scene
* Date Created - 9/16/2022
* Date Revisions:
	9/17/2022 - Added global variable instead of prewritten text
"""
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
