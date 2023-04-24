"""
* Programmer Name - Jason Truong
* Description - File for the market where the player buy/sell/trade items
* Date Created - 9/16/2022
* Date Revisions:
	9/17/2022 - Added soundeffects and bg music
"""
extends Node

const POWER_COST = 50

signal bought_powerup(pwr)

"""
/*
* @pre Button is pressed
* @post Purchase and apply powerup
* @param None
* @return None
*/
"""
func _on_buySpeedPowerup_pressed():
	if(Save.game_data.money >= POWER_COST): #checks if money is adequate
		if Global.state != Global.scenes.MAIN_MENU:
			GameLoot.add_to_coin(ServerConnection._player_num, -POWER_COST)
			ServerConnection.send_money_earned(-POWER_COST)
		else:
			GlobalSettings.save_money(-POWER_COST)
			show_balance()
		Global.powerup = "speed"
		GlobalSignals.emit_signal("bought_powerup", Global.powerup)

"""
/*
* @pre Button is pressed
* @post Purchase and apply powerup
* @param None
* @return None
*/
"""
func _on_buyStrengthPowerup_pressed():
	if(Save.game_data.money >= POWER_COST): #checks if money is adequate
		if Global.state != Global.scenes.MAIN_MENU:
			GameLoot.add_to_coin(ServerConnection._player_num, -POWER_COST)
			ServerConnection.send_money_earned(-POWER_COST)
		else:
			GlobalSettings.save_money(-POWER_COST)
			show_balance()
		Global.powerup = "strength"
		GlobalSignals.emit_signal("bought_powerup", Global.powerup)

"""
/*
* @pre Button is pressed
* @post Purchase and apply powerup
* @param None
* @return None
*/
"""
func _on_buyEndurancePowerup_pressed():
	if(Save.game_data.money >= POWER_COST): #checks if money is adequate
		if Global.state != Global.scenes.MAIN_MENU:
			GameLoot.add_to_coin(ServerConnection._player_num, -POWER_COST)
			ServerConnection.send_money_earned(-POWER_COST)
		else:
			GlobalSettings.save_money(-POWER_COST)
			show_balance()
		Global.powerup = "endurance"
		GlobalSignals.emit_signal("bought_powerup", Global.powerup)

"""
/*
* @pre Button is pressed
* @post Purchase and apply powerup
* @param None
* @return None
*/
"""
func _on_buyReachPowerup_pressed():
	if(Save.game_data.money >= POWER_COST): #checks if money is adequate
		if Global.state != Global.scenes.MAIN_MENU:
			GameLoot.add_to_coin(ServerConnection._player_num, -POWER_COST)
			ServerConnection.send_money_earned(-POWER_COST)
		else:
			GlobalSettings.save_money(-POWER_COST)
			show_balance()
		Global.powerup = "reach"
		GlobalSignals.emit_signal("bought_powerup", Global.powerup)

"""
/*
* @pre Button is pressed
* @post Purchase and apply powerup
* @param None
* @return None
*/
"""
func _on_buyLuckPowerup_pressed():
	if(Save.game_data.money >= POWER_COST): #checks if money is adequate
		if Global.state != Global.scenes.MAIN_MENU:
			GameLoot.add_to_coin(ServerConnection._player_num, -POWER_COST)
			ServerConnection.send_money_earned(-POWER_COST)
		else:
			GlobalSettings.save_money(-POWER_COST)
			show_balance()
		Global.powerup = "luck"
		GlobalSignals.emit_signal("bought_powerup", Global.powerup)

"""
/*
* @pre Button is pressed
* @post Purchase and apply powerup
* @param None
* @return None
*/
"""
func _on_buySusPowerup_pressed():
	if(Save.game_data.money >= POWER_COST): #checks if money is adequate
		if Global.state != Global.scenes.MAIN_MENU:
			GameLoot.add_to_coin(ServerConnection._player_num, -POWER_COST)
			ServerConnection.send_money_earned(-POWER_COST)
		else:
			GlobalSettings.save_money(-POWER_COST)
			show_balance()
		Global.powerup = "sus"
		GlobalSignals.emit_signal("bought_powerup", Global.powerup)

"""
/*
* @pre Button is pressed
* @post Purchase and apply powerup
* @param None
* @return None
*/
"""
func _on_buyGlowPowerup_pressed():
	if(Save.game_data.money >= POWER_COST): #checks if money is adequate
		if Global.state != Global.scenes.MAIN_MENU:
			GameLoot.add_to_coin(ServerConnection._player_num, -POWER_COST)
			ServerConnection.send_money_earned(-POWER_COST)
		else:
			GlobalSettings.save_money(-POWER_COST)
			show_balance()
		Global.powerup = "glow"
		GlobalSignals.emit_signal("bought_powerup", Global.powerup)

func show_balance():
	$Balance.show()
	$Balance.text = "Balance: " + str(Save.game_data.money)
