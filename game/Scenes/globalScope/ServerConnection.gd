extends Node

const KEY := "nakama_mendax"

var _session: NakamaSession

var _client := Nakama.create_client(KEY, "44.202.34.182", 7350, "http")


func authenticate_async(email:String, password:String) -> int:
	var result := OK
	
	var new_session: NakamaSession = yield(_client.authenticate_email_async(email,password,null,true), "completed")
	
	if not new_session.is_exception():
		_session = new_session
	else:
		result = new_session.get_exception().status_code
	
	return result
