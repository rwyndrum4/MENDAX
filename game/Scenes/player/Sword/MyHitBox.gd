"""
* Programmer Name - Jason Truong
* Description - Code for player's sword
* Date Created - 11/20/2022
			
"""
class_name MyHitBox

extends Area2D

export var damage := 10

"""
/*
* @pre Called when made
* @post Initializes the collision layer and mask
* @param None
* @return void
*/
"""
func _init() -> void:
	collision_layer = 19
	collision_mask = 0
