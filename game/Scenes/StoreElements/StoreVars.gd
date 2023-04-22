"""
* Programmer Name - Jason Truong
* Description - File for the market where the player buy/sell/trade items
* Date Created - 9/16/2022
* Date Revisions:
	9/17/2022 - Added soundeffects and bg music
"""
extends Node

onready var prior

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
	if Global.lastPos == "shop":
		print("got here")
		Global.state = Global.scenes.CAVE
	else:
		Global.state = Global.scenes.MAIN_MENU

"""
/*
* @pre Button is pressed
* @post Purchase and apply powerup
* @param None
* @return None
*/
"""
func _on_buySpeedPowerup_pressed():
	if(Global.money >= 10): #checks if money is adequate
		Global.money -= 10 #removes 10
		Global.powerup = "speed"

"""
/*
* @pre Button is pressed
* @post Purchase and apply powerup
* @param None
* @return None
*/
"""
func _on_buyStrengthPowerup_pressed():
	if(Global.money >= 10): #checks if money is adequate
		Global.money -= 10 #removes 10
		Global.powerup = "strength"

"""
/*
* @pre Button is pressed
* @post Purchase and apply powerup
* @param None
* @return None
*/
"""
func _on_buyEndurancePowerup_pressed():
	if(Global.money >= 10): #checks if money is adequate
		Global.money -= 10 #removes 10
		Global.powerup = "endurance"

"""
/*
* @pre Button is pressed
* @post Purchase and apply powerup
* @param None
* @return None
*/
"""
func _on_buyReachPowerup_pressed():
	if(Global.money >= 10): #checks if money is adequate
		Global.money -= 10 #removes 10
		Global.powerup = "reach"

"""
/*
* @pre Button is pressed
* @post Purchase and apply powerup
* @param None
* @return None
*/
"""
func _on_buyLuckPowerup_pressed():
	if(Global.money >= 10): #checks if money is adequate
		Global.money -= 10 #removes 10
		Global.powerup = "luck"

"""
/*
* @pre Button is pressed
* @post Purchase and apply powerup
* @param None
* @return None
*/
"""
func _on_buySusPowerup_pressed():
	if(Global.money >= 10): #checks if money is adequate
		Global.money -= 10 #removes 10
		Global.powerup = "sus"

"""
/*
* @pre Button is pressed
* @post Purchase and apply powerup
* @param None
* @return None
*/
"""
func _on_buyGlowPowerup_pressed():
	if(Global.money >= 10): #checks if money is adequate
		Global.money -= 10 #removes 10
		Global.powerup = "glow"
