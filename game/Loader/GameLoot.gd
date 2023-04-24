"""
This class is just for counting the amount of money that each player earns in a round
Separtate instance from the player invenetory, which also has money being added to it
	but both should be consistent with eachother
"""

extends Node

var PlayerLoot: Array = []

func _ready():
	# warning-ignore:return_value_discarded
	ServerConnection.connect("someone_earned_money", self, "server_update_money")

"""
* @pre need to know how many players in game
* @post Sets all current players
* @param num_players (number of players in game)
* @return None
"""
func init_players(num_players:int) -> void:
	PlayerLoot = []
	for i in range(1,num_players+1):
		var dict: Dictionary = {
			"p_num": i,
			"num_coin": 0
		}
		PlayerLoot.append(dict)

"""
* @pre None
* @post Gets the current value of what coin
* @param player_num (number of player in game [1-4])
* @return int
"""
func get_coin_val(player_num: int) -> int:
	return PlayerLoot[player_num-1]["num_coin"]

"""
* @pre None
* @post Adds coins to game loot AND updates other parts of inventory/save
* @param player_num (player to add money to [1-4])
* 		 num_coin (number of coins to add/sub from total)
* @return None
"""
func add_to_coin(player_num:int, num_coin:int) -> void:
	PlayerLoot[player_num-1]["num_coin"] += num_coin
	#If local player save to inventory and savedata
	if player_num == ServerConnection._player_num:
		GlobalSettings.save_money(num_coin)
		PlayerInventory.add_item("Coin", num_coin)
		GlobalSignals.emit_signal("money_screen_val")

"""
* @pre None
* @post Whenever someone picks up some money that is not tracked locally
* @param id (id of player [0-3]), amount (amount of money picked up)
* @return int
"""
func server_update_money(id: int, amount: int) -> void:
	PlayerLoot[id]["num_coin"] += amount

func reset() -> void:
	PlayerLoot = []
