"""
* Programmer Name - Jason Truong
* Description - File for the market where the player buy/sell/trade items
* Date Created - 9/16/2022
* Date Revisions:
	9/17/2022 - Added soundeffects and bg music
"""
extends Node

"""
/*
* @pre None
* @post None
* @param None
* @return None
*/
"""
func _ready():
	pass#$tavernbg.play() #constant looping bg music
"""
/*
* @pre Button is pressed
* @post Player's money gets added
* @param None
* @return None
*/
"""
func _on_addMoney_pressed():
	Global.money += 1 #adds 1
	$Kaching.play() #plays sound
	
"""
/*
* @pre Button is pressed
* @post Player's money gets subtracted
* @param None
* @return None
*/
"""
func _on_subMoney_pressed():
	if(Global.money != 0): #checks if money is 0
		Global.money -= 1 #subtracts 1
		$Kaching.play() #plays sound

"""
/*
* @pre Button is pressed
* @post Goes back to main menu scene
* @param None
* @return None
*/
"""
func _on_Back2Menu_pressed():
	Global.state = Global.scenes.MAIN_MENU
	


