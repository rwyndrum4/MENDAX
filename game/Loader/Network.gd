"""
* Programmer Name - Jason Truong
* Description - Network file for multiplayer implementation
* Date Created - 10/3/2022
* Date Revisions:
	
* Citations:
	Based on tutorial from https://www.youtube.com/watch?v=lpkaMKE081M&list=PL6bQeQE-ybqDmGuN7Nz4ZbTAqyCMyEHQa
"""


extends Node


const DEFAULT_PORT = 28960
const MAX_CLIENTS = 4

var server = null
var client = null

var ip_address = ""

"""
/*
* @pre None
* @post Sets the ip address based on the OS type
* @param None
* @return None
*/
"""
func _ready() -> void:
	if OS.get_name() == "Windows":
		ip_address = IP.get_local_addresses()[3]
	elif OS.get_name() == "Android":
		ip_address = IP.get_local_addresses()[0]
	else:
		ip_address = IP.get_local_addresses()[3]
		
	for ip in IP.get_local_addresses():
		if ip.begins_with("192.168.") and not ip.ends_with(".1"):
			ip_address = ip
	
	get_tree().connect("connected_to_server", self, "_connected_to_server")
	get_tree().connect("server_disconnected", self, "_server_disconnected")
	get_tree().connect("connection_failed", self, "_connection_failed")


"""
/*
* @pre Takes max clients and default port that has been pre set
* @post Creates a server with the port and max clients given
* @param None
* @return None
*/
"""
func create_server() -> void:
	server = NetworkedMultiplayerENet.new() #creates new server
	server.create_server(DEFAULT_PORT, MAX_CLIENTS)
	get_tree().set_network_peer(server)

"""
/*
* @pre Takes ip address and default port set by _ready func
* @post Creates a client with the port and ip address given
* @param None
* @return None
*/
"""
func join_server() -> void:
	client = NetworkedMultiplayerENet.new() #creates new server
	client.create_client(ip_address, DEFAULT_PORT)
	get_tree().set_network_peer(client)

"""
/*
* @pre None
* @post Prints out a string when successfully connected
* @param None
* @return None
*/
"""
func _connected_to_server() -> void:
	print("Successfully connected to the server")

"""
/*
* @pre None
* @post Prints out a string when disconnecting
* @param None
* @return None
*/
"""
func _server_disconnected() -> void:
	print("Disconnected from the server")
