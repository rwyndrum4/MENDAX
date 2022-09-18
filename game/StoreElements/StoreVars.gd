extends Node
func _ready():
	$tavernbg.play()

func _on_addMoney_pressed():
	Global.money += 1
	$Kaching.play()
	

func _on_subMoney_pressed():
	if(Global.money != 0):
		Global.money -= 1
		$Kaching.play()


func _on_Back2Menu_pressed():
	SceneTrans.change_scene("res://Game.tscn")
	


