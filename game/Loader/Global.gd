"""
* Programmer Name - Jason Truong
* Description - File for global variables such as health, money, and etc.
* Date Created - 9/16/2022
* Date Revisions:
	- N/A
"""
extends Node

# Player's balance
var money = 0

# Current scene
var state = null
enum scenes {
	MAIN_MENU,
	MARKET,
	START_AREA,
	CAVE,
	RIDDLER_MINIGAME
}
