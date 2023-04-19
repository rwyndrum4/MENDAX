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
	$Stars.play("default")
	add_scores()
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

func add_scores() -> void:
	var silver_font = DynamicFont.new()
	silver_font.font_data = load("res://Assets/Silver.ttf")
	silver_font.size = 80
	silver_font.outline_size = 4
	silver_font.outline_color = Color.blue
	silver_font.use_filter = true
	var score_label: Label = Label.new()
	score_label.text = "Scores:"
	score_label.add_font_override("font",silver_font)
	score_label.add_color_override("font_color",Color.white)
	$Scores.add_child(score_label)
	for val in GameLoot.PlayerLoot:
		var p_name = Global.get_player_name(val.get("p_num"))
		var s_font = DynamicFont.new()
		s_font.font_data = load("res://Assets/Silver.ttf")
		s_font.size = 40
		s_font.outline_size = 4
		s_font.outline_color = Color(0,0,0,1)
		s_font.use_filter = true
		var s_label: Label = Label.new()
		s_label.text = p_name + ": " + str(val.get("num_coin"))
		s_label.add_font_override("font",s_font)
		s_label.add_color_override("font_color",Color.white)
		$Scores.add_child(s_label)

func _on_MainMenu_pressed():
	Global.state = Global.scenes.MAIN_MENU

func _on_Quit_pressed():
	get_tree().quit()
