extends Node

signal chat_message_received(username, text)

const KEY := "nakama_mendax"

var _session: NakamaSession

#my server: 3.143.142.232
#jasons server: 44.202.34.182
var _client := Nakama.create_client(KEY, "3.143.142.232", 7350, "http")
var _socket : NakamaSocket

var _channel_id = ""

func authenticate_async(email:String, password:String) -> int:
	var result := OK
	
	var new_session: NakamaSession = yield(_client.authenticate_email_async(email,password), "completed")
	
	if not new_session.is_exception():
		_session = new_session
	else:
		result = new_session.get_exception().status_code
	
	return result

func connect_to_server_async() -> int:
	_socket = Nakama.create_socket_from(_client)
	var result: NakamaAsyncResult = yield(_socket.connect_async(_session), "completed")
	if not result.is_exception():
		#connect to closed signal, called when connection is closed to free memory
		_socket.connect("closed", self, "_on_NakamaSocket_closed")
		#connect 
		_socket.connect("received_channel_message", self, "_on_Nakama_Socket_received_channel_message")
		return OK
	return ERR_CANT_CONNECT

func _on_NakamaSocket_closed() -> void:
	print("Disconnected from socket")
	_socket = null

func join_chat_async() -> int:
	var chat_join_result = yield(
		_socket.join_chat_async("general", NakamaSocket.ChannelType.Room, false, false), "completed"
	)
	if not chat_join_result.is_exception():
		_channel_id = chat_join_result.id
		print("Chat joined")
		return OK
	else:
		print("Chat NOT joined")
		return ERR_CONNECTION_ERROR

func send_text_async(text: String) -> int:
	if not _socket:
		return ERR_UNAVAILABLE
	
	if _channel_id == "":
		printerr("Can't send a message to chat: _channel_id is missing")
	
	var msg_result = yield(
		_socket.write_chat_message_async(_channel_id, {"msg": text}), "completed"
	)
	return ERR_CONNECTION_ERROR if msg_result.is_exception() else OK

func _on_Nakama_Socket_received_channel_message(message: NakamaAPI.ApiChannelMessage) -> void:
	if message.code != 0:
		return
	
	var content: Dictionary = JSON.parse(message.content).result
	if Global.chat_username == "":
		Global.chat_username = message.sender_id
	emit_signal("chat_message_received", message.sender_id, content.msg)
