"""
* Programmer Name - Freeman Spray
* Description - Code for animating the players' escape from the cave
* Date Created - 3/11/2023
* Date Revisions:
"""
extends Control

var tick = 0
var player2Exited = false
var player3Exited = false
var player4Exited = false
var num_players

# Called when the node enters the scene tree for the first time.
func _ready():
	num_players = 1
	if ServerConnection.match_exists() and ServerConnection.get_server_status():
		num_players = len(Global.player_names.values())


# Called every frame. 'delta' is the elapsed time since the previous frame (remove the '_' if you want to use).
func _process(_delta):
	tick+=1
	if tick == 30 and num_players > 1:
		$PlayerSprite2.show()
		player2Exited = true
	if tick == 60 and num_players > 2:
		$PlayerSprite3.show()
		player3Exited = true
	if tick == 90 and num_players > 3:
		$PlayerSprite4.show()
		player4Exited = true
	if $PlayerSprite.position.y < 800:
		$PlayerSprite.position.x = $PlayerSprite.position.x * 1.004
		$PlayerSprite.position.y = $PlayerSprite.position.y * 1.0025
		$PlayerSprite.scale = $PlayerSprite.scale * 1.0035
	if $PlayerSprite2.position.y < 800 and player2Exited:
		$PlayerSprite2.position.x = $PlayerSprite2.position.x * 1.004
		$PlayerSprite2.position.y = $PlayerSprite2.position.y * 1.0025
		$PlayerSprite2.scale = $PlayerSprite2.scale * 1.0035
	if $PlayerSprite3.position.y < 800and player3Exited:
		$PlayerSprite3.position.x = $PlayerSprite3.position.x * 1.004
		$PlayerSprite3.position.y = $PlayerSprite3.position.y * 1.0025
		$PlayerSprite3.scale = $PlayerSprite3.scale * 1.0035
	if $PlayerSprite4.position.y < 800and player4Exited:
		$PlayerSprite4.position.x = $PlayerSprite4.position.x * 1.004
		$PlayerSprite4.position.y = $PlayerSprite4.position.y * 1.0025
		$PlayerSprite4.scale = $PlayerSprite4.scale * 1.0035
	
