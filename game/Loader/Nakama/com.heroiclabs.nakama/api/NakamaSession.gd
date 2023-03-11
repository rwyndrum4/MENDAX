extends NakamaAsyncResult
class_name NakamaSession
# warnings-disable

var created : bool = false : set = _no_set
var token : String = "" : set = _no_set
var create_time : int = 0 : set = _no_set
var expire_time : int = 0 : set = _no_set
var expired : bool = true : get = is_expired, set = _no_set
var vars : Dictionary = {} : set = _no_set
var username : String = "" : set = _no_set
var user_id : String = "" : set = _no_set
var refresh_token : String = "" : set = _no_set
var refresh_expire_time : int = 0 : set = _no_set
var valid : bool = false : get = is_valid, set = _no_set

func _no_set(v):
	return

func is_expired() -> bool:
	return expire_time < Time.get_unix_time_from_system()

func would_expire_in(p_secs : int) -> bool:
	return expire_time < Time.get_unix_time_from_system() + p_secs

func is_refresh_expired() -> bool:
	return refresh_expire_time < Time.get_unix_time_from_system()

func is_valid():
	return valid

func _init(p_token = null,p_created : bool = false,p_refresh_token = null,p_exception = null,p_exception):
	if p_token:
		created = p_created
		_parse_token(p_token)
	if p_refresh_token:
		_parse_refresh_token(p_refresh_token)

func refresh(p_session):
	if p_session.token:
		_parse_token(p_session.token)
	if p_session.refresh_token:
		_parse_refresh_token(p_session.refresh_token)

func _parse_token(p_token):
	var decoded = _jwt_unpack(p_token)
	if decoded.is_empty():
		valid = false
		return
	valid = true
	token = p_token
	create_time = Time.get_unix_time_from_system()
	expire_time = int(decoded.get("exp", 0))
	username = str(decoded.get("usn", ""))
	user_id = str(decoded.get("uid", ""))
	vars = {}
	if decoded.has("vrs") and typeof(decoded["vrs"]) == TYPE_DICTIONARY:
		for k in decoded["vrs"]:
			vars[k] = decoded["vrs"][k]

func _parse_refresh_token(p_refresh_token):
	var decoded = _jwt_unpack(p_refresh_token)
	if decoded.is_empty():
		return
	refresh_expire_time = int(decoded.get("exp", 0))
	refresh_token = p_refresh_token

func _to_string():
	if is_exception():
		return get_exception()._to_string()
	return "Session<created=%s, token=%s, create_time=%d, username=%s, user_id=%s, vars=%s, expire_time=%d, refresh_token=%s refresh_expire_time=%d>" % [
		created, token, create_time, username, user_id, str(vars), expire_time, refresh_token, refresh_expire_time]

func _jwt_unpack(p_token : String) -> Dictionary:
	# Hack decode JSON payload from JWT.
	if p_token.find(".") == -1:
		_ex = NakamaException.new("Missing payload: %s" % p_token)
		return {}
	var payload = p_token.split('.')[1];
	var pad_length = ceil(payload.length() / 4.0) * 4;
	# Pad base64
	for i in range(0, pad_length - payload.length()):
		payload += "="
	payload = payload.replace("-", "+").replace("_", "/")
	var unpacked = Marshalls.base64_to_utf8(payload)
	if not validate_json(unpacked):
		var test_json_conv = JSON.new()
		test_json_conv.parse(unpacked)
		var decoded = test_json_conv.get_data()
		if typeof(decoded) == TYPE_DICTIONARY:
			return decoded
	_ex = NakamaException.new("Unable to unpack token: %s" % p_token)
	return {}
