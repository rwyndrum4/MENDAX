"""
* Programmer Name - Freeman Spray
* Description - Code for controlling the Dilemma 'minigame'
* Date Created - 2/19/2023
* Date Revisions:
"""
extends Node2D

onready var textBox = $textBox


"""
/*
* @pre Called when the node enters the scene tree for the first time.
* @post hides player torch and begins dilemma exchange
* @param None
* @return None
*/
"""
func _ready():
	# Turn off player's torch
	$Player.get_node("Torch1").hide()
	textBox.queue_text("It seems I was wrong to underestimate you, hero.")
	textBox.queue_text("You have proven yourself time and again, besting my trials of cunning, strength, and skill.")
	textBox.queue_text("You have risen above your companions.")
	textBox.queue_text("But what will you win, if you defeat me? What will come of this harrowing adventure?")
	textBox.queue_text("If I die, the secret of my treasure will go with me.")
	textBox.queue_text("So I offer you this choice now:")
	textBox.queue_text("bury a dagger in the back of one of your companions, and part of that treasure can be yours.")
	textBox.queue_text("It can be any one of them. Surely there's one you won't miss?")
	textBox.queue_text("I'll give you some time to think about it.")

"""
/*
* @pre Called for every frame
* @post updates timer and changes scenes if player presses enter and is in the zone
* @param _delta -> time variable that can be optionally used
* @return None
*/
"""
func _process(_delta):
	if textBox.text_queue.empty():
		$Button1.show()
		$Button2.show()
		$Button3.show()
		$Button4.show()
		$ButtonGlow1.show()
		$ButtonGlow2.show()
		$ButtonGlow3.show()
		$ButtonGlow4.show()


func _on_Button1_pressed():
	Global.progress += 1
	Global.state = Global.scenes.CAVE

func _on_Button2_pressed():
	Global.progress += 1
	Global.state = Global.scenes.CAVE


func _on_Button3_pressed():
	Global.progress += 1
	Global.state = Global.scenes.CAVE


func _on_Button4_pressed():
	Global.progress += 1
	Global.state = Global.scenes.CAVE
