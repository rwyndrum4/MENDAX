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

signal chat_message_received(username, text)

#Key that is stored in the server
const KEY := "nakama_mendax"

var _session: NakamaSession

#my server: 18.222.220.187
#jasons server: 52.205.252.95
var _client := Nakama.create_client(KEY, "18.222.220.187", 7350, "http")
var _socket : NakamaSocket

var _general_chat_id = ""
var _current_whisper_id = ""

var room_users:Dictionary = {}

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
	var deviceid = OS.get_unique_id()
	
	var new_session: NakamaSession = yield(_client.authenticate_device_async(deviceid), "completed")
	
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
	print("Disconnected from socket")
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
		"user_sent": "",
		"from_user": Save.game_data.username,
		"type": "whisper"
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

