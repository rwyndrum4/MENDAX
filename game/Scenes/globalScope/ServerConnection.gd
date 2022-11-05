"""
* Programmer Name - Ben Moeller, Jason Truong
* Description - File for setting up connection to the server and sending messages
* Date Created - 10/9/2022
* Date Revisions:
	10/12/2022 - Start of adding network functionality
	10/14/2022 - Got general chat working for player
	10/22/2022 - Adding scene changer functionality
"""
extends Node

#Opcodes used to send to server about what is happening in game
enum OpCodes {
	UPDATE_POSITION = 1,
	UPDATE_INPUT,
	UPDATE_STATE,
	UPDATE_JUMP,
	DO_SPAWN,
	UPDATE_COLOR,
	INITIAL_STATE
}

#Variable that checks if connected to server
var server_status: bool = false

#Signals for recieving game state data from server (from  the .lua files)
signal state_updated(positions, inputs) #state of game has been updated
signal initial_state_received(positions, inputs, names) #first state of game
signal character_spawned(id, char_name, current_players) #singal to tell if someone has spawned

#Other signals
signal chat_message_received(msg,type,user_sent,from_user) #signal to tell game a chat message has come in

const KEY := "nakama_mendax" #Key that is stored in the server

var _session: NakamaSession #User session

#bens server: 18.118.82.24
#jasons server: 52.205.252.95
var _client := Nakama.create_client(KEY, "18.118.82.24", 7350, "http")
var _socket : NakamaSocket

var _general_chat_id = "" #id for communicating in general room
var _current_whisper_id = "" #id for person you want to whisper
var _world_id: String = "" #id of the world you are currently in
var _device_id: String = "" #id of the user's computer generated id
var room_users: Dictionary = {} #chatroom users
var _match_id: String = "" #String to hold match id

"""
/*
* @pre called to set server status
* @post sets server status to value passed in
* @param status -> bool
* @return None
*/
"""
func set_server_status(status: bool):
	server_status = status

"""
/*
* @pre called when game wants server status
* @post returns the status
* @param None
* @return bool
*/
"""
func get_server_status() -> bool:
	return server_status

"""
/*
* @pre called once to authenticate user
* @post authenticates to the server using device id
* @param None
* @return None
*/
"""
func authenticate_async() -> int:
	var result := OK
	_device_id = OS.get_unique_id()
	
	var new_session: NakamaSession = yield(_client.authenticate_device_async(_device_id), "completed")
	
	if not new_session.is_exception():
		_session = new_session
	else:
		result = new_session.get_exception().status_code
	
	return result

"""
/*
* @pre called once to connect user to server
* @post connects to server using ip set by server
* @param None
* @return None
*/
"""
func connect_to_server_async() -> int:
	_socket = Nakama.create_socket_from(_client)
	var result: NakamaAsyncResult = yield(_socket.connect_async(_session), "completed")
	var new_username = Save.game_data.username
	yield(_client.update_account_async(_session, new_username), "completed")
	if not result.is_exception():
		#connect to closed signal, called when connection is closed to free memory
		# warning-ignore:return_value_discarded
		_socket.connect("closed", self, "_on_NakamaSocket_closed")
		#connect
		# warning-ignore:return_value_discarded
		_socket.connect("received_channel_message", self, "_on_Nakama_Socket_received_channel_message")
		#get user who joins
		# warning-ignore:return_value_discarded
		_socket.connect("received_channel_presence", self, "_on_channel_presence")
		#get a notification
		# warning-ignore:return_value_discarded
		_socket.connect("received_notification", self, "_on_notification")
		#warning-ignore: return_value_discarded
		_socket.connect("received_match_state", self, "_on_NakamaSocket_received_match_state")
		return OK
	return ERR_CANT_CONNECT

"""
/*
* @pre called when Nakama Socket is closed
* @post sets _socket to null to close socket
* @param None
* @return None
*/
"""
func _on_NakamaSocket_closed() -> void:
	_socket = null

"""
/*
* @pre called once to join the general chat
* @post joins the general chat server, can now send messages
* @param None
* @return None
*/
"""
func join_chat_async_general() -> int:
	var chat_join_result = yield(
		_socket.join_chat_async("general", NakamaSocket.ChannelType.Room, false, false), "completed"
	)
	if not chat_join_result.is_exception():
		for p in chat_join_result.presences:
			room_users[p.username] = p.user_id
		_general_chat_id = chat_join_result.id
		print("Chat joined")
		return OK
	else:
		print("Chat NOT joined")
		return ERR_CONNECTION_ERROR

"""
/*
* @pre called when joining a whisper chat
* @post sends whisper message corresponding to username
* @param input -> String, has_id_already -> bool
		 input can either be a user name or user id
		 has_id_already lets the function know if input is an id
* @return None
*/
"""
func join_chat_async_whisper(input:String, has_id_already:bool) -> int:
	var user_id:String
	if has_id_already:
		user_id = input
	else:
		user_id = room_users[input]
	if user_id == "ERROR":
		return ERR_CONNECTION_ERROR
	var type = NakamaSocket.ChannelType.DirectMessage
	var persistence = true
	var hidden = false
	var channel : NakamaRTAPI.Channel = yield(_socket.join_chat_async(user_id, type, persistence, hidden), "completed")
	_current_whisper_id = channel.id
	if channel.is_exception():
		return ERR_CONNECTION_ERROR
	else:
		return OK


"""
/*
* @pre called when sending message to server
* @post sends chat message packaged with the username
* @param text -> String
* @return None
*/
"""
func send_text_async_general(text: String) -> int:
	if not _socket:
		return ERR_UNAVAILABLE
	
	if _general_chat_id == "":
		printerr("Can't send a message to chat: _channel_id is missing")
	
	var msg_result = yield(
		_socket.write_chat_message_async(_general_chat_id, 
		{"msg": text, 
		"user_sent": "n/a",
		"from_user": Save.game_data.username,
		"type": "general"
		}), "completed")
	return ERR_CONNECTION_ERROR if msg_result.is_exception() else OK

func send_text_async_whisper(text: String,user_sent_to:String) -> int:
	if not _socket:
		return ERR_UNAVAILABLE
	
	if _general_chat_id == "":
		printerr("Can't send a message to chat: _channel_id is missing")
	
	var msg_result = yield(
		_socket.write_chat_message_async(_current_whisper_id, 
		{"msg": text, 
		"user_sent": user_sent_to,
		"from_user": Save.game_data.username,
		"type": "whisper"
		}), "completed")
	return ERR_CONNECTION_ERROR if msg_result.is_exception() else OK

#"""
#/*
#* @pre called when user joins the game world
#* @post joins the world
#* @param None
#* @return None
#*/
#"""
#func join_world_async() -> int:
#	var world: NakamaAPI.ApiRpc = yield(_client.rpc_async(_session, "get_world_id", ""), "completed")
#	if not world.is_exception():
#		_world_id = world.payload
#	else:
#		print("rpc_async failed")
#		return ERR_CONNECTION_ERROR
#
#	var match_join_result: NakamaRTAPI.Match = yield(_socket.join_match_async(_world_id), "completed")
#	if match_join_result.is_exception():
#		var exception: NakamaException = match_join_result.get_exception()
#		print("Error joining the match: %s - %s" % [exception.status_code, exception.message])
#		return ERR_CONNECTION_ERROR
#	else:
#		return OK

"""
/*
* @pre None
* @post creates match for user when with given match name
* @param lobby_name -> String
* @return None
*/
"""
func create_match(lobby_name:String) -> Array:
	_match_id = lobby_name
	var game_match: NakamaRTAPI.Match = yield(_socket.create_match_async(_match_id), "completed")
	return game_match.presences

"""
/*
* @pre None
* @post joins the match of a given name
* @param lobby_name -> String
* @return None
*/
"""
func join_match(lobby_name:String) -> Array:
	var game_match = yield(_socket.join_match_async(lobby_name), "completed")
	return game_match.presences

"""
/*
* @pre None
* @post leave a given match
* @param lobby_name -> String
* @return None
*/
"""
func leave_match(lobby_name:String) -> int:
	var leave: NakamaAsyncResult = yield(_socket.leave_match_async(lobby_name), "completed")
	if leave.is_exception():
		return ERR_CANT_RESOLVE
	else:
		return OK

"""
/*
* @pre None
* @post tells if there is a match going on or not
* @param None
* @return None
*/
"""
func match_exists():
	return _match_id != ""

"""
/*
* @pre None
* @post leaves the current user match
* @param None
* @return None
*/
"""
func reset_match():
	leave_match(_match_id)
	_match_id = ""

"""
/*
* @pre None
* @post returns the current matches in the server
* @param None
* @return Array 
*/
"""
func current_matches() -> Array:
	var min_players = 2
	var max_players = 4
	var limit = 10
	var authoritative = true
	var label = ""
	var query = ""
	var result: NakamaRTAPI.Match = yield(_client.list_matches_async(_session,min_players, max_players, limit, authoritative, label, query), "completed")
	return result.matches

"""
/*
* @pre called when you want to send your position to the server
* @post sends data to server, and to other players from server
* @param position -> Vector2
* @return None
*/
"""
func send_position_update(position: Vector2) -> void:
	if _socket:
		var payload := {id = _device_id, pos = {x=position.x, y = position.y}}
		_socket.send_match_state_async(_match_id, OpCodes.UPDATE_POSITION,JSON.print(payload))

"""
/*
* @pre called when you want to let server know you are changing directions
* @post sends to server and other players
* @param input -> float
* @return None
*/
"""
func send_input_update(input: float) -> void:
	if _socket:
		var payload := {id = _device_id, inp = input}
		_socket.send_match_state_async(_match_id, OpCodes.UPDATE_INPUT,JSON.print(payload))

"""
/*
* @pre called when you want to tell server you have spawned (aka entered world)
* @post tells server and other players you are in the game
* @param name -> String
* @return None
*/
"""
func send_spawn(char_name: String) -> void:
	if _socket:
		var payload := {id = _device_id, nm = char_name}
		_socket.send_match_state_async(_match_id, OpCodes.DO_SPAWN,JSON.print(payload))


"""
/*
* @pre called when a message is received from Nakama server
* @post emits signal that the message has been received
* @param message -> NakamaAPI.APIChannelMessage
* @return None
*/
"""
func _on_Nakama_Socket_received_channel_message(message: NakamaAPI.ApiChannelMessage) -> void:
	if message.code != 0:
		return
	
	var content: Dictionary = JSON.parse(message.content).result
	
	
	emit_signal("chat_message_received",content.msg,content.type,content.user_sent,content.from_user)

"""
/*
* @pre called when someone enters or leaves the server
* @post adds/deletes person to room_users
* @param p_presence -> NakamaRTAPI.ChannelPresenceEvent
* @return None
*/
"""
func _on_channel_presence(p_presence : NakamaRTAPI.ChannelPresenceEvent):
	for p in p_presence.joins:
		room_users[p.username] = p.user_id

	for p in p_presence.leaves:
		# warning-ignore:return_value_discarded
		room_users.erase(p.username)
	print("users in room: ",room_users)
	Global.current_players = room_users

"""
/*
* @pre called when someone makes a whisper
* @post connects the whisper chat
* @param p_notification -> NakamaAPI.ApiNotification
* @return None
*/
"""
func _on_notification(p_notification : NakamaAPI.ApiNotification):
	join_chat_async_whisper(p_notification._get_sender_id(),true)

"""
/*
* @pre called when received a match state from the server
* @post does the corresponding operation
* @param match_state -> NakamaRTAPI.MatchData
* @return None
*/
"""
func _on_NakamaSocket_received_match_state(match_state: NakamaRTAPI.MatchData) -> void:
	var code := match_state.op_code
	var raw := match_state.data
	
	match code:
		OpCodes.UPDATE_STATE:
			var decoded: Dictionary = JSON.parse(raw).result
			
			var positions: Dictionary = decoded.pos
			var inputs: Dictionary = decoded.inp
			
			emit_signal("state_updated", positions, inputs)
		OpCodes.INITIAL_STATE:
			var decoded: Dictionary = JSON.parse(raw).result
			
			var positions: Dictionary = decoded.pos
			var inputs: Dictionary = decoded.inp
			var names: Dictionary = decoded.nms
			
			emit_signal("initial_state_received", positions, inputs, names)
		OpCodes.DO_SPAWN:
			var decoded: Dictionary = JSON.parse(raw).result
			
			var _id: String = decoded.id
			var _char_name: String = decoded.nm
			
			emit_signal("character_spawned", room_users)
