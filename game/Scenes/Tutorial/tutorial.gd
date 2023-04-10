"""
* Programmer Name - Jason Truong
* Description - Code for controlling what happens in the tutorial scene
* Date Created - 4/7/2023
* Date Revisions:
	-
"""
extends Node2D

onready var torch = $Player/light/Torch1
onready var main_player = $Player

onready var textbox = $textBox 
onready var foreground_trees = $ParallaxForeground
onready var ground_sword = $sword_pickup/TextureRect

var swordObj = preload("res://Scenes/player/Sword/Sword.tscn")
var swordPivot = null
var sword = null
var bruh:int = 0


"""
/*
* @pre Called when the node enters the scene tree for the first time.
* @post updates starts the timer
* @param None
* @return None
*/
"""
func _ready():
	torch.set_process(false)
	var skeleton = load("res://Scenes/Mobs/skeleton.tscn").instance()
	skeleton._in_tutorial = true
	add_child(skeleton)
	skeleton.position = Vector2(3000,500)
	skeleton.set_physics_process(false)
	skeleton.pos2d.scale.x = -1
	skeleton.scale = Vector2(3,3)
	skeleton.get_node("detector").queue_free()
	
	foreground_trees.visible = true
	textbox.queue_text("Welcome to the tutorial!")
	textbox.queue_text("Use the Arrow keys or WASD to move your character!")
	# warning-ignore:return_value_discarded
	GlobalSignals.connect("enemyDefeated", self, "tutorial_enemy_dead")

"""
/*
* @pre Called for every frame
* @post updates timer and changes scenes if player presses enter and is in the zone
* @param _delta -> time variable that can be optionally used
* @return None
*/
"""
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta): #change to delta if used
	if is_instance_valid(sword):
		handle_swords()


"""
/*
* @pre None
* @post updates the sword positions of ALL players in game
* @param None
* @return None
*/
"""
func handle_swords():

	#main player's sword
	if sword.direction == "right":
		swordPivot.position = main_player.position + Vector2(60,0)
	elif sword.direction == "left":
		swordPivot.position = main_player.position + Vector2(-60,0)

"""
/*
* @pre Called when body is entered
* @post textbox output
* @param area2d
* @return None
*/
"""
func _on_blocked_road_detector_area_entered(_area):
	
	if bruh == 5:
		textbox.queue_text("I SAID THE F***ING ROAD IS BLOCKED!")
		textbox.queue_text("TURN AROUND!!!!")
	elif bruh == 6:
		get_tree().quit()
	else:
		textbox.queue_text("The road is blocked!")
	bruh+=1



func _on_sword_pickup_area_entered(_area):
	
	ground_sword.visible = false

	call_deferred("we_da_best")
	$sword_pickup.queue_free()
	textbox.queue_text("You picked up a sword!")
	textbox.queue_text("Oh look there is an enemy! Go an attack it with LMB or Spacebar!")

func we_da_best():
	var my_sword = swordObj.instance()
	main_player.add_child(my_sword)
	sword = my_sword
	swordPivot = sword.get_node("pivot")
	sword.direction = "right"
	swordPivot.position = main_player.position + Vector2(60,20)

func tutorial_enemy_dead(_id):
	textbox.queue_text("You have killed the enemy!")
	textbox.queue_text("Let's find shelter for the night!")


func _on_cave_area_entered(_area):
	SceneTrans.change_scene(Global.scenes.MAIN_MENU)
