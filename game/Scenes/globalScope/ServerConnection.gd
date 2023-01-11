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
	UPDATE_RIDDLER_RIDDLE,
	UPDATE_ARENA_SWORD,
	UPDATE_ARENA_PLAYER_HEALTH,
	UPDATE_ARENA_ENEMY_HIT,
	UPDATE_RHYTHM_SCORE,
	SPAWNED
}

#Variable that checks if connected to server
var server_status: bool = false

#Signals for recieving game state data from server (from  the .lua files)
signal state_updated(id, position) #state of game has been updated
signal input_updated(id, vec) #input of player has changed and received
signal character_spawned(char_name) #singal to tell if someone has spawned
signal character_despawned(char_name) #signal to tell if someone has despawned
signal riddle_received(riddle) #signal to tell game it has received a riddle from server
signal arena_player_swung_sword(id, direction) #signal to tell arena minigame someone swung sword
signal arena_player_lost_health(id, health) #signal to tell if player has lost health
signal arena_enemy_hit(enemmy_hit, damage_taken) #signal to tell if an enemy has been hit
signal minigame_player_spawned(id) #signal to tell if a player has arrived to a scene
signal minigame_rhythm_score(id, score)

#Other signals
signal chat_message_received(msg,type,user_sent,from_user) #signal to tell game a chat message has come in

const KEY := "nakama_mendax" #key that is stored in the server
var IP_ADDRESS: String = "18.117.251.238" #ip address of server

var _session: NakamaSession #user session

#bens server: 18.118.82.24
#jasons server: 52.205.252.95
var _client := Nakama.create_client(KEY, IP_ADDRESS, 7350, "http") #server client
var _socket : NakamaSocket #server socket connection

var _general_chat_id: String = "" #id for communicating in general room
var _current_whisper_id = "" #id for person you want to whisper
var _group_chat_id: String = "" #id of the match's private group chat
var _current_chat_id = "" #the current id that a message should be sent to
var _is_global_chat: bool = true
var _group_id: String = "" #id of match group (NOT THE CHAT ID, ITS DIFFERENT)
var _world_id: String = "" #id of the world you are currently in
var _device_id: String = "" #id of the user's computer generated id
var _match_id: String = "" #String to hold match id
var _player_num: int = 0 #Number of the player
var chatroom_users: Dictionary = {} #chatroom users
var connected_opponents: Dictionary = {} #opponents currently in match (including you)
var game_match = null #holds the current game match information once created

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
* @pre None
* @post switches from using global chat to group chat and vice versa
* @param None
* @return None
*/
"""
func switch_chat_methods():
	_is_global_chat = not _is_global_chat

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
* @pre called when game wants users in chatroom (global)
* @post returns the chatroom dictionary
* @param None
* @return Dictionary
*/
"""
func get_chatroom_players() -> Dictionary:
	return chatroom_users

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
		_socket.connect("received_channel_presence", self, "_on_channel_presence_general")
		#get a notification
		# warning-ignore:return_value_discarded
		_socket.connect("received_notification", self, "_on_notification")
		#warning-ignore: return_value_discarded
		_socket.connect("received_match_state", self, "_on_NakamaSocket_received_match_state")
		#warning-ignore: return_value_discarded
		_socket.connect("received_match_presence", self, "_on_NakamaSocket_received_match_precence")
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
			chatroom_users[p.username] = p.user_id
		_general_chat_id = chat_join_result.id
		return OK
	else:
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
		user_id = chatroom_users[input]
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
* @pre called when joining a group chat
* @post sends group message
* @param None
* @return None
*/
"""
func join_chat_async_group() -> int:
	var loc_group_id = _group_id
	var persistence = true
	var hidden = false
	var type = NakamaSocket.ChannelType.Group
	var channel : NakamaRTAPI.Channel = yield(_socket.join_chat_async(loc_group_id, type, persistence, hidden), "completed")
	_group_chat_id = channel.id 
	print("Connected to group channel: '%s'" % [channel.id])
	return OK


"""
/*
* @pre None
* @post creates group in the server
* @param group_name -> String
* @return None
*/
"""
func create_match_group(group_name: String):
	var group: NakamaAPI.ApiGroup = yield(_client.create_group_async(_session, group_name), "completed")
	_group_id = group.id
	if group.is_exception():
		print("Group was not formed: %s" % group)

"""
/*
* @pre None
* @post joins a group that has already been made
* @param None
* @return None
*/
"""
func join_match_group():
	var join: NakamaAsyncResult = yield(_client.join_group_async(_session, _group_id), "completed")
	if join.is_exception():
		print("An error occurred: %s" % join)

"""
/*
* @pre None
* @post leaves the match group
* @param None
* @return None
*/
"""
func leave_match_group():
	var leave : NakamaAsyncResult = yield(_client.leave_group_async(_session, _group_id), "completed")
	if leave.is_exception():
		print("An error occurred: %s" % leave)

"""
/*
* @pre None
* @post sends a message to server based on if in global or match chat
* @param text -> String (message to send to other players)
* @return None
*/
"""
func send_chat_message(text: String):
	if _is_global_chat:
		yield(send_text_async_general(text), "completed")
	else:
		yield(send_text_async_group(text), "completed")

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
	
	var msg_result = yield(
		_socket.write_chat_message_async(_general_chat_id, 
		{"msg": text, 
		"user_sent": "n/a",
		"from_user": Save.game_data.username,
		"type": "general"
		}), "completed")
	return ERR_CONNECTION_ERROR if msg_result.is_exception() else OK

"""
/*
* @pre called when sending message to server
* @post sends chat message to group packaged with the username
* @param text -> String
* @return None
*/
"""
func send_text_async_group(text: String) -> int:
	if not _socket:
		return ERR_UNAVAILABLE
	
	var msg_result = yield(
		_socket.write_chat_message_async(_group_chat_id, 
		{"msg": text, 
		"user_sent": "n/a",
		"from_user": Save.game_data.username,
		"type": "general"
		}), "completed")
	return ERR_CONNECTION_ERROR if msg_result.is_exception() else OK

func send_text_async_whisper(text: String,user_sent_to:String) -> int:
	if not _socket:
		return ERR_UNAVAILABLE
	
	var msg_result = yield(
		_socket.write_chat_message_async(_current_whisper_id, 
		{"msg": text, 
		"user_sent": user_sent_to,
		"from_user": Save.game_data.username,
		"type": "whisper"
		}), "completed")
	return ERR_CONNECTION_ERROR if msg_result.is_exception() else OK

"""
/*
* @pre None
* @post creates match for user when with given match name
* @param lobby_name -> String
* @return None
*/
"""
func create_match(lobby_name:String) -> Array:
	game_match = yield(_socket.create_match_async(lobby_name), "completed")
	Global.add_match(lobby_name,game_match.match_id, _group_id)
	_match_id = game_match.match_id
	send_text_async_general("MATCH_RECEIVED " + JSON.print(Global.current_matches))
	return game_match.presences

"""
/*
* @pre None
* @post joins the match of a given name
* @param id -> String
* @return None
*/
"""
func join_match(id:String) -> Dictionary:
	game_match = yield(_socket.join_match_async(id), "completed")
	_match_id = game_match.match_id
	for p in game_match.presences:
		connected_opponents[p.user_id] = p.username
	return game_match.presences

"""
/*
* @pre None
* @post leave a given match
* @param lobby_name -> String
* @return None
*/
"""
func leave_match(id:String) -> int:
	_match_id = ""
	var leave: NakamaAsyncResult = yield(_socket.leave_match_async(id), "completed")
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
* @pre called when you want to send your position to the server
* @post sends data to server, and to other players from server
* @param position -> Vector2
* @return None
*/
"""
func send_position_update(position: Vector2) -> void:
	#if socket is in place and player is moving
	if _socket and position != Global.get_player_pos(_player_num):
		var payload = {id = _player_num, pos = {x=position.x, y = position.y}}
		_socket.send_match_state_async(_match_id, OpCodes.UPDATE_POSITION,JSON.print(payload))

"""
/*
* @pre called when you want to let server know you are changing directions
* @post sends to server and other players
* @param input -> float
* @return None
*/
"""
func send_input_update(in_vec:Vector2) -> void:
	#if socket is in place and player is moving
	if _socket and in_vec != Global.get_player_input_vec(_player_num):
		var payload := {id = _player_num, x_in = in_vec.x, y_in = in_vec.y}
		_socket.send_match_state_async(_match_id, OpCodes.UPDATE_INPUT,JSON.print(payload))

"""
/*
* @pre called when Player 1 needs to communicate to other players what riddle is
* @post tells server what riddle to send to others is
* @param riddle -> String
* @return None
*/
"""
func send_riddle(riddle_in: String, answer_in:String) -> void:
	if _socket:
		var payload := {riddle = riddle_in, answer = answer_in}
		_socket.send_match_state_async(_match_id, OpCodes.UPDATE_RIDDLER_RIDDLE, JSON.print(payload))

"""
/*
* @pre called when player attempts to hit someone in arena minigame
* @post tells server which player swung their sword
* @param None
* @return None
*/
"""
func send_arena_sword(direction: String):
	if _socket:
		var payload := {id = _player_num, dir = direction}
		_socket.send_match_state_async(_match_id, OpCodes.UPDATE_ARENA_SWORD, JSON.print(payload))

"""
/*
* @pre called when player gets hit in arena minigame
* @post tells server which player got hit and sends their current health
* @param health_in -> int
* @return None
*/
"""
func send_arena_player_health(health_in: int):
	if _socket:
		var payload := {id = _player_num, health = health_in}
		_socket.send_match_state_async(_match_id, OpCodes.UPDATE_ARENA_PLAYER_HEALTH, JSON.print(payload))

"""
/*
* @pre called when enemy gets hit in a minigame
* @post tells server which enemy got hit and how much damage it took
* @param damage -> int (how much damage enemy took), enemy_hit -> int (enum value)
* @return None
*/
"""
func send_arena_enemy_hit(damage: int, enemy_hit: int):
	if _socket:
		var payload := {enemy = enemy_hit, dmg = damage}
		_socket.send_match_state_async(_match_id, OpCodes.UPDATE_ARENA_ENEMY_HIT, JSON.print(payload))

"""
/*
* @pre called when someone needs to send a score update for rhythm game
* @post tells server which player is getting updated
* @param new_score -> int (new score for the player)
* @return None
*/
"""
func send_rhythm_score(new_score:int):
	if _socket:
		var payload := {id = _player_num, score = new_score}
		_socket.send_match_state_async(_match_id, OpCodes.UPDATE_RHYTHM_SCORE, JSON.print(payload))

"""
/*
* @pre called when player spawns in an area
* @post tells other players they are there, used for syncing players together
* @param None
* @return None
*/
"""
func send_spawn_notif():
	if _socket:
		var payload := {id = _player_num}
		_socket.send_match_state_async(_match_id, OpCodes.SPAWNED, JSON.print(payload))

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
func _on_channel_presence_general(p_presence : NakamaRTAPI.ChannelPresenceEvent):
	send_text_async_general("MATCH_RECEIVED " + JSON.print(Global.current_matches))
	for p in p_presence.joins:
		chatroom_users[p.username] = p.user_id
		
	for p in p_presence.leaves:
		# warning-ignore:return_value_discarded
		chatroom_users.erase(p.username)
	print("users in room: ",chatroom_users)

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
* @pre called when received match precense from match
* @post sends updates current presences in Global
* @param p_notification -> NakamaAPI.ApiNotification
* @return None
*/
"""
func _on_NakamaSocket_received_match_precence(p_match_presence_event : NakamaRTAPI.MatchPresenceEvent):
	for p in p_match_presence_event.joins:
		connected_opponents[p.user_id] = p
		emit_signal("character_spawned", p.username)
	for p in p_match_presence_event.leaves:
		emit_signal("character_despawned", p.username)
		# warning-ignore:return_value_discarded
		connected_opponents.erase(p.user_id)

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
		OpCodes.UPDATE_POSITION: #Received position of a player
			var decoded: Dictionary = JSON.parse(raw).result
			
			var id: int = int(decoded.id)
			var position_decoded: Dictionary = decoded.pos
			var position: Vector2 = Vector2(int(position_decoded.x),int(position_decoded.y))
			
			emit_signal("state_updated", id, position)
		OpCodes.UPDATE_INPUT: #Received that a player has changed directions
			var decoded: Dictionary = JSON.parse(raw).result
			
			var id: int = int(decoded.id)
			var x = decoded.x_in
			var y = decoded.y_in
			var out_vec: Vector2 = Vector2(x,y)
			
			emit_signal("input_updated", id, out_vec)
		OpCodes.UPDATE_RIDDLER_RIDDLE: #Received riddle from player one
			var decoded: Dictionary = JSON.parse(raw).result
			
			var riddle: String = decoded.riddle
			var answer: String = decoded.answer
			
			emit_signal("riddle_received", riddle, answer)
		OpCodes.UPDATE_ARENA_SWORD:
			var decoded: Dictionary = JSON.parse(raw).result
			
			var id: int = int(decoded.id)
			var direction: String = decoded.dir
			
			emit_signal("arena_player_swung_sword", id, direction)
		OpCodes.UPDATE_ARENA_PLAYER_HEALTH:
			var decoded: Dictionary = JSON.parse(raw).result
			
			var id: int = int(decoded.id)
			var health: int = int(decoded.health)
			
			emit_signal("arena_player_lost_health", id, health)
		OpCodes.UPDATE_ARENA_ENEMY_HIT:
			var decoded: Dictionary = JSON.parse(raw).result
			
			var enemy: int = int(decoded.enemy)
			var dmg_taken: int = int(decoded.dmg)
			
			emit_signal("arena_enemy_hit", enemy, dmg_taken)
		OpCodes.UPDATE_RHYTHM_SCORE:
			var decoded: Dictionary = JSON.parse(raw).result
			
			var id: int = int(decoded.id)
			var score: int = int(decoded.score)
			
			emit_signal("minigame_rhythm_score", id, score)
		OpCodes.SPAWNED:
			var decoded: Dictionary = JSON.parse(raw).result
			
			var id: int = int(decoded.id)
			
			emit_signal("minigame_player_spawned", id)
