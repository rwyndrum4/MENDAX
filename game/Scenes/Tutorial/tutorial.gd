"""
* Programmer Name - Jason Truong
* Description - Code for controlling what happens in the tutorial scene
* Date Created - 4/7/2023
* Date Revisions:
	-
"""
extends Node2D

onready var confuzzed = $Player/confuzzle
onready var torch = $Player/light/Torch1
onready var main_player = $Player
onready var button = $HUD/Button
onready var textbox = $textBox 
onready var foreground_trees = $ParallaxForeground
onready var ground_sword = $sword_pickup/TextureRect
onready var timer = $HUD/Timer
onready var blinkAnim = $"Blink(#Blackpink_Fan)/AnimationPlayer"
onready var _fog1 = $FOG/fog/ParallaxCloud/Sprite
onready var _fog2 = $FOG/fog/ParallaxCloud2/Sprite
onready var _fog3 = $FOG/fog/ParallaxCloud3/Sprite
onready var _fog4 = $ParallaxForeground/ParallaxCloud/Sprite

var swordObj = preload("res://Scenes/player/Sword/Sword.tscn")
var swordPivot = null
var sword = null
var bruh:int = 0
var timer_created = 0
var blink_count:int = 0
var grabbed = 0

signal textWait()

"""
/*
* @pre Called when the node enters the scene tree for the first time.
* @post updates starts the timer
* @param None
* @return None
*/
"""
func _ready():
	_fog1.modulate.a = 0
	_fog2.modulate.a = 0
	_fog3.modulate.a = 0
	_fog4.modulate.a = 0
	torch.set_process(false)
	var skeleton = load("res://Scenes/Mobs/skeleton.tscn").instance()
	var imposta = load("res://Scenes/Mobs/imposter.tscn").instance()
	skeleton._in_tutorial = true
	add_child(skeleton)
	add_child(imposta)
	skeleton.position = Vector2(3000,500)
	imposta.position = Vector2(5000, 500)
	skeleton.set_physics_process(false)
	imposta.set_physics_process(false)
	imposta.timer.stop()
	imposta.scale = Vector2(0.798,0.813)
	skeleton.pos2d.scale.x = -1
	skeleton.scale = Vector2(3,3)
	skeleton.get_node("detector").queue_free()

	foreground_trees.visible = true
	textbox.queue_text("Welcome to the tutorial!")
	textbox.queue_text("It is pretty dark out! Let's find shelter!")
	textbox.queue_text("Use the Arrow keys or WASD to move your character!")
	# warning-ignore:return_value_discarded
	GlobalSignals.connect("enemyDefeated", self, "tutorial_enemy_dead")
	# warning-ignore:return_value_discarded
	connect("textWait", self, "_finish_anim")
	Global.in_anim = 1;
	Global.anim_id = 0
	



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
	fog_position()
	if main_player.isInverted == true:
		confuzzed.visible = true
	else:
		confuzzed.visible = false
	if is_instance_valid(sword):
		handle_swords()
	if main_player.velocity.x == 0 and main_player.velocity.y == 0 and timer_created == 0 and Global.in_anim == 0:
		timer_created = 1
		timer.start()
	elif timer_created == 1 and main_player.velocity.x == 0 and main_player.velocity.y == 0:
		pass
	else:
		timer.stop()
		timer_created = 0
		
		if button.self_modulate.a >= 0:
			button.self_modulate.a -=.05
		elif button.self_modulate.a <= 0:
			button.visible = false	

"""
/*
* @pre An input of any sort
* @post None
* @param Takes in an event
* @return None
*/
"""
func _input(_ev):
	if textbox.queue_text_length() == 0 and Global.in_anim == 1:
		Global.in_anim = 0
		emit_signal("textWait", Global.anim_id)
	if Input.is_action_just_pressed("green_rhythm"):
		if grabbed == 0:	
			button.grab_focus()
			grabbed = 1
		else:
			button.release_focus()
			grabbed = 0


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


"""
/*
* @pre Called when body is entered
* @post sword gets queue freed
* @param area2d
* @return None
*/
"""
func _on_sword_pickup_area_entered(_area):
	
	ground_sword.visible = false

	call_deferred("we_da_best")
	$sword_pickup.queue_free()
	textbox.queue_text("You picked up a sword!")
	textbox.queue_text("There is an enemy! Go an attack it with LMB or Spacebar!")
	$sword_notice2.queue_free()
	$StaticBody2D/NoPass.queue_free()
"""
/*
* @pre None
* @post Adds sword as a child to player and intializes it
* @param None
* @return None
*/
"""
func we_da_best():
	var my_sword = swordObj.instance()
	main_player.add_child(my_sword)
	sword = my_sword
	swordPivot = sword.get_node("pivot")
	sword.direction = "right"
	swordPivot.position = main_player.position + Vector2(60,20)

"""
/*
* @pre When enemy is killed
* @post textbox output
* @param id: not used
* @return None
*/
"""
func tutorial_enemy_dead(_id):
	if _id == 0:
		$skele_block.queue_free()
		$StaticBody2D/NoPass2.queue_free()
		textbox.queue_text("You have killed the enemy!")
		textbox.queue_text("Let's quickly find shelter before more show up!")
	if _id == 1111:
		$imposta_block.queue_free()
		$StaticBody2D/NoPass3.queue_free()
		textbox.queue_text("What was that?!")
		textbox.queue_text("I feel dizzy from it.")
		textbox.queue_text("*I need to find shelter before more weird things happen*")

"""
/*
* @pre Area entered
* @post Changes scene to main menu
* @param area2d
* @return None
*/
"""
func _on_cave_area_entered(_area):
	if blink_count == 0:
		$cave/CollisionShape2D.queue_free()
		blinkAnim.play("BLINK")
		yield(blinkAnim, "animation_finished")
		textbox.queue_text("*I am getting tired...*")
	elif blink_count == 1:
		$cave/CollisionShape2D2.queue_free()
		blinkAnim.play("BLINKBLINK")
		yield(blinkAnim, "animation_finished")
		textbox.queue_text("*I really need to find a place quick...*")
	else:
		$cave/CollisionShape2D3.queue_free()
		blinkAnim.play("BLIIIINK_BLIIIIIINK")
		yield(blinkAnim, "animation_finished")
		SceneTrans.change_scene(Global.scenes.MAIN_MENU)
		Global.anim_id = 2
		
		
	blink_count +=1

"""
/*
* @pre Button appeared after afking for 3 seconds
* @post Changes scene to main menu
* @param None
* @return None
*/
"""
func _on_Button_pressed():
	SceneTrans.change_scene(Global.scenes.MAIN_MENU)
	button.visible = false
	


func _on_Timer_timeout():
	timer_created = 0
	button.visible = true
	while button.self_modulate.a <= 1:
		button.self_modulate.a +=.05


func _finish_anim(id):
	#if is start
	if id == 0:
		button.visible = true



"""
/*
* @pre Area entered
* @post Queue frees sword image and displays text
* @param area2d
* @return None
*/
"""
func _on_sword_notice_area_entered(_area):

	textbox.queue_text("Oh look there is a sword!")
	textbox.queue_text("Go pick it up!")
	$sword_notice.queue_free()


"""
/*
* @pre Area entered
* @post Tells player to pick up sword
* @param area2d
* @return None
*/
"""
func _on_sword_notice2_area_entered(_area):
	textbox.queue_text("Pick up the sword first before continuing!")


"""
/*
* @pre Area entered
* @post Tells player to kill skeleton first
* @param area2d
* @return None
*/
"""
func _on_skele_block_area_entered(_area):
	textbox.queue_text("Kill the skeleton before moving forward!")


func _on_imposta_notice_area_entered(_area):
	textbox.queue_text("Oh look there is somewhere over there!")
	textbox.queue_text("Let's talk to them!")
	$imposta_notice.queue_free()


func _on_imposta_block_area_entered(_area):
	textbox.queue_text("Go talk to that person first!")

func fog_position():
	var playerPos = main_player.position.x
	var target = 5000
	var result = (target - playerPos) / 10000
	if result <= 0 and abs(result) < 1:
		_fog1.modulate.a = abs(result)
		_fog2.modulate.a = abs(result)
		_fog3.modulate.a = abs(result)
		_fog4.modulate.a = abs(result)

	elif result <= 0 and abs(result) > 1:
		_fog1.modulate.a = 1
		_fog2.modulate.a = 1
		_fog3.modulate.a = 1
		_fog4.modulate.a = 1

	else:
		_fog1.modulate.a = 0
		_fog2.modulate.a = 0
		_fog3.modulate.a = 0
		_fog4.modulate.a = 0

