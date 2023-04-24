extends Node

const BUFFER = Vector2(0, -250)

func _on_right_side_tp_area_entered(_area):
	var new_pos = $left_side_tp.position + BUFFER
	GlobalSignals.emit_signal("teleport_player", new_pos)


func _on_left_side_tp_area_entered(_area):
	var new_pos = $right_side_tp.position - BUFFER
	GlobalSignals.emit_signal("teleport_player", new_pos)
