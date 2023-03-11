"""
* Programmer Name - Ben Moeller
* Description - File for controlling online rhythm game activity
* Date Created - 1/9/2023
* Date Revisions: 
"""

extends Node

func _ready():
	# warning-ignore:return_value_discarded
	ServerConnection.connect("minigame_rhythm_score",Callable(self,"_handle_new_score"))

func _handle_new_score(player_id:int, new_score:int):
	get_parent().change_score_from_server(Global.get_player_name(player_id), new_score)

func send_score_to_server(new_score:int):
	ServerConnection.send_rhythm_score(new_score)

func setup_players(your_name:String):
	var names: Array = Global.player_names.values()
	names.erase(your_name)
	for p_name in names:
		get_parent().add_player_score(p_name)
