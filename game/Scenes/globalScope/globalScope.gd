extends Node

onready var server_connection := $ServerConnection

func _ready():
	request_authentication()

func request_authentication():
	var email := "test@test2.com"
	var password := "password"
	
	var result: int = yield(server_connection.authenticate_async(email,password), "completed")
	if result == OK:
		print("Authenticated user %s successfully" % email)
	else:
		print("Could not authenticate user %s" % email)
