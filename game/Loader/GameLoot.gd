extends Node

var PlayerLoot: Array = []

func _ready():
	ServerConnection.connect("someone_earned_money", self, "server_update_money")

"""
* @pre need to know how many players in game
* @post Sets all current players
* @param num_players (number of players in game)
* @return None
"""
func init_players(num_players:int) -> void:
	for i in range(1,num_players+1):
		var dict: Dictionary = {
			"p_num": i,
			"num_coin": 0
		}
		PlayerLoot.append(dict)

"""
* @pre None
* @post Gets the current value of what coin
* @param player_num (number of players in game)
* @return int
"""
func get_coin_val(player_num: int) -> int:
	return PlayerLoot[player_num-1]["num_coin"]

"""
* @pre None
* @post Gets the current value of what coin
* @param player_num (number of players in game)
* 		 num_coin (number of coins to add/sub from total)
* @return int
"""
func add_to_coin(player_num:int, num_coin:int) -> void:
	PlayerLoot[player_num-1]["num_coin"] += num_coin

"""
* @pre None
* @post Whenever someone picks up some money that is not tracked locally
* @param id (id of player), amount (amount of money picked up)
* @return int
"""
func server_update_money(id: int, amount: int) -> void:
	PlayerLoot[id]["num_coin"] += amount

func reset() -> void:
	PlayerLoot = []
