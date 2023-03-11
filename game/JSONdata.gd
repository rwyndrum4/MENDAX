"""
* Programmer Name - Will Wyndrum
* Description - persist inventory
* Date Created - 10/10/2022
* Date Revisions:
* Citations:
	Based on tutorial from https://www.youtube.com/watch?v=FHYb63ppHmk
"""
extends Node

var item_data: Dictionary

func _ready():
	item_data = get_data("res://Inventory/Data/ItemData.json")

func get_data(filepath):
	var file := File.new()
	var result: int = file.open(filepath, file.READ)
	assert(result == OK) #,str("Invalid filepath: ", filepath))
	
	var text := file.get_as_text()
	var jsonErr: String = validate_json(text)
	assert(jsonErr.is_empty()) #,str("Invalid JSON: ", jsonErr))
	
	var test_json_conv = JSON.new()
	test_json_conv.parse(text)
	var jsonRes = test_json_conv.get_data()
	assert(typeof(jsonRes) == TYPE_DICTIONARY) #,str("Not a Dictionary: ", jsonRes))
	
	var dict: Dictionary = jsonRes
	return dict
