extends Node

#Key: [num_notes:int, lanes, note_types, heights]
# note_types: 1 -> normal, 2-> hold
# map starts at beat 2 for some reason
var beatmap:Dictionary = {
	2: [1,[1],[1],[0]],
	3: [1,[1],[1],[0]],
	4: [1,[1],[1],[0]],
	5: [1,[1],[1],[0]]
}
