"""
* Programmer Name - Freeman Spray, Mohit Garg, Ben Moeller
* Description - Code for controlling the Riddle minigame
* Date Created - 10/14/2022
* Date Revisions:
	10/19/2022 -Added hidden item detector functionality -Mohit Garg
	10/22/2022 -Added hidden item detector for multiple hints-Mohit Garg
	11/30/2022 -Added changes to sync riddles between the players -Ben Moeller
"""
extends Control

# Member Variables
var in_menu = false
var answer = ""#set in init riddle
var riddle_dict = {} #stores riddles and their answers
var item = null
var ItemClass = preload("res://Inventory/Item.tscn")
var other_player = "res://Scenes/player/other_players/other_players.tscn" #Scene for players that online oppenents use

# Scene Nodes
onready var riddlemap=preload("res://Scenes/minigames/riddler/riddlerMap.tscn")
onready var myTimer: Timer = $GUI/Timer
onready var timerText: Label = $GUI/Timer/timerText
onready var textBox = $GUI/textBox
onready var hintbox=$GUI/show_letter
onready var itemarray=[] #determines if items have been found
onready var tilepositionsx=[]# creates array of tile positions fo rhints
onready var tilepositionsy=[]# creates array of tile positions fo rhints
onready var validtiles=[] #array of valid tiles for positioning
onready var hint="";# set in init riddle
onready var riddle="";#set in init riddle
onready var riddlefile = 'res://Assets/riddle_jester/riddles.txt'
onready var currenthints=""; #keeps track of currenhints found
onready var hintlength=0#keeps track of hintlength to give random letter clues
onready var answerlength=0 #keeps track of asnwer length is constant
onready var itemsleft=6;#helps  withi giving hints
onready var lettersleft=0;#helps with giving hints
onready var x_overlap=[] #array to prevent horizontal overlap with hints 
onready var y_overlap=[]#array to prevent vertical overlap with hints 
onready var init_playerpos; #initial player position helps with hint placement
onready var transCam = $Path2D/PathFollow2D/camTrans
onready var riddler = $riddler
onready var playerCam = $Player/Camera2D
onready var player_one = $Player #Player object of player YOU control

#signals
signal textWait()
	
"""
/*
* @pre Called when the node enters the scene tree for the first time.
* @post updates starts the timer
* @param file
* @return None
*/
"""
func _ready():
	player_one.set_physics_process(false)
	init_playerpos=$Player.position
	# warning-ignore:return_value_discarded
	ServerConnection.connect("riddle_received", self, "set_riddle_from_server")
	# warning-ignore:return_value_discarded
	Global.connect("all_players_arrived", self, "_can_send_riddle")
	# warning-ignore:return_value_discarded
	GlobalSignals.connect("openChatbox", self, "chatbox_use")
	#If there is a multiplayer match
	if ServerConnection.match_exists() and ServerConnection.get_server_status():
		# warning-ignore:return_value_discarded
		GlobalSignals.connect("answer_received",self,"_check_answer")
		ServerConnection.send_spawn_notif()
		spawn_players()
		#Send riddle if player is player 1
		if ServerConnection._player_num == 1:
			init_riddle(riddlefile) #initalizes riddle randomly
			init_hiddenitems() #initalizes hidden items array and other things needed
			if Global.get_minigame_players() == Global.get_num_players() - 1:
				ServerConnection.send_riddle(riddle,answer)
				start_riddle_game()
			#Sends the riddle to other players once all are present
		else:
			#If player doesn't receive riddle from server in 5 seconds, they get their own riddle
			#If they got the riddle successfully nothing else will happen
			var wait_for_riddle_timer: Timer = Timer.new()
			add_child(wait_for_riddle_timer)
			wait_for_riddle_timer.wait_time = Global.WAIT_FOR_PLAYERS_TIME
			wait_for_riddle_timer.one_shot = true
			wait_for_riddle_timer.start()
			# warning-ignore:return_value_discarded
			wait_for_riddle_timer.connect("timeout",self, "_riddle_timer_expired", [wait_for_riddle_timer])
	#If there is a single player game, start game right away
	else:
		get_parent().chat_box.connect("message_sent", self, "_single_player_check_answer")
		init_riddle(riddlefile) #initalizes riddle randomly
		init_hiddenitems() #initalizes hidden items array and other things needed
		start_riddle_game()

"""
/*
* @pre Called for every frame
* @post updates timer and changes scenes if player presses enter and is in the zone
* @param _delta -> time variable that can be optionally used
* @return None
*/
"""
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta): #change to delta if used
	timerText.text = convert_time(myTimer.time_left)

"""
/*
* @pre An input of any sort
* @post None
* @param Takes in an event
* @return None
*/
"""
func _input(_ev):
	if textBox.queue_text_length() == 0 and Global.in_anim == 1:
		Global.in_anim = 0
		emit_signal("textWait")
	#DEBUG PURPOSES - REMOVE FOR FINAL GAME!!!
	#IF YOU PRESS P -> TIMER WILL REDUCE TO 3 SECONDS
	if Input.is_action_just_pressed("timer_debug_key",false):
		myTimer.start(3)
	#IF YOU PRESS Q -> TIMER WILL INCREASE TO ARBITRARILY MANY SECONDS
	if Input.is_action_just_pressed("extend_timer_debug_key",false):
		myTimer.start(30000)

"""
/*
* @pre None
* @post Starts timer for minigame, sets playerCam to current, and sets physic_process to True
* @param None
* @return None
*/
"""
func _finish_anim():
	var t = Timer.new()
	t.set_wait_time(1)
	t.set_one_shot(false)
	self.add_child(t)
		
	t.start()
	yield(t, "timeout")

	$Path2D/AnimationPlayer.play_backwards("BEGIN")
	yield($Path2D/AnimationPlayer, "animation_finished")
	t.start()
	yield(t, "timeout")
	
	#start timer
	textBox.queue_text("Time starts now!")
	myTimer.start(300)
	
	#remove jester
	riddler.queue_free()
	
	t.queue_free()
	$Player.set_physics_process(true)
	playerCam.current = true

"""
/*
* @pre None
* @post starts the game and opening animations
* @param None
* @return None
*/
"""
func start_riddle_game():
	Global.reset_minigame_players()
	player_one.set_physics_process(true)
	#play riddle animations
	var t = Timer.new()
	t.set_wait_time(1)
	t.set_one_shot(false)
	self.add_child(t)
	transCam.current = true
	$Player.set_physics_process(false)
	#Begin scene dialogue
	textBox.queue_text("Oh who do we have here?")
	t.start()
	yield(t, "timeout")
	t.queue_free()
	$Path2D/AnimationPlayer.play("BEGIN")
	yield($Path2D/AnimationPlayer, "animation_finished")
	textBox.queue_text("In order to pass you must solve this riddle...")
	textBox.queue_text(riddle)
	textBox.queue_text("Please enter the answer in the chat once you have it, there are hints hidden here if you need them (:")
	# warning-ignore:return_value_discarded
	connect("textWait", self, "_finish_anim")
	Global.in_anim = 1;
	Global.riddle_answer = answer

"""
/*
* @pre wait_for_riddle_timer expired
* @post If player hasn't got a riddle from the server, give them their own
* @param None
* @return None
*/
"""
func _riddle_timer_expired(timer:Timer):
	if riddle == "":
		init_riddle(riddlefile) #initalizes riddle randomly
		init_hiddenitems() #initalizes hidden items array and other things needed
		textBox.queue_text("Never received riddle from server, you have your own riddle")
		start_riddle_game()
		#Make it so server can't change riddle anymore
		ServerConnection.disconnect( "riddle_received", self, "set_riddle_from_server")
	timer.queue_free()

"""
/*
* @pre Called when you received riddle from other player
* @post Set the riddle and answer
* @param riddle_in -> String, answer_in -> String
* @return None
*/
"""
func set_riddle_from_server(riddle_in:String, answer_in:String) -> void:
	riddle = riddle_in
	hint = answer_in
	answer = answer_in
	init_hiddenitems()
	start_riddle_game()

"""
/*
* @pre Called when someone spawns into the minigame
* @post update player count and send riddle if all players are here
* @param _id -> int (player id, not needed), current_num -> int (current number of players in minigame)
* @return None
*/
"""
func _can_send_riddle():
	ServerConnection.send_riddle(riddle,answer)
	start_riddle_game()

"""
/*
* @pre Called when the node enters the scene tree for the first time.
* @post Updates riddle answer and riddle hint
* @param None
* @return None
*/
"""
func init_riddle(file):
	var f = File.new()
	f.open(file, File.READ)
	var key=1
	while !f.eof_reached():
		var line=f.get_line()
		riddle_dict[key]=line
		key=key+1
	f.close()
	var number=0
	while number==0 or number%2==0:
		randomize()
		number = randi() % key 
	if(number%2==1): #inidcates line contains hint
		riddle= str(riddle_dict[number])
		hint=str(riddle_dict[number+1])
		answer=hint

"""
/*
* @pre Called when someone in server game guesses an answer
* @post Leaves scene if they guess right
* @param answer -> String, from_user -> String (who message came from)
* @return None
*/
"""
func _check_answer(answer_in:String, from_user: String):
	if answer == answer_in:
		handle_coins(from_user)
		Global.state = Global.scenes.CAVE

"""
/*
* @pre Game has ended
* @post Records the coin values for all players
* @param who_won -> String (name of person who won)
* @return None
*/
"""
func handle_coins(who_won:String):
	for p_name in Global.player_names.values():
		var how_much: int = 0
		var message:String = ""
		if p_name == who_won:
			message = "Correct answer! +20 gold for you"
			how_much = 20
		else:
			message = "Someone else found the answer, +5 gold for you"
			how_much = 5
		var n = Global.get_player_num(p_name)
		GameLoot.add_to_coin(n,how_much)
		if p_name == Save.game_data.username:
			var total_coin = GameLoot.get_coin_val(n)
			GlobalSignals.emit_signal("money_screen_val", total_coin)
			GlobalSignals.emit_signal("exportEventMessage", message, "blue")
			PlayerInventory.add_item("Coin", how_much)

"""
/*
* @pre Called when someone guesses an answer in single player mode
* @post Leaves scene if they guess right
* @param message_in -> String (guess at answer)
* @return None
*/
"""
func _single_player_check_answer(message_in:String, _whisper, _username):
	if answer == message_in:
		Global.reset_minigame_players()
		var message = "Correct answer! +20 gold for you"
		GlobalSignals.emit_signal("exportEventMessage", message, "blue")
		GameLoot.add_to_coin(1,20)
		var total_coin = GameLoot.get_coin_val(1)
		GlobalSignals.emit_signal("money_screen_val", total_coin)
		PlayerInventory.add_item("Coin", 20)
		Global.state = Global.scenes.CAVE

"""
/*
* @pre Called when need to convert seconds to MIN:SEC format
* @post Returns string of current time
* @param time_in -> float 
* @return String (text of current time left)
*/
"""
func convert_time(time_in:float) -> String:
	var rounded_time = int(time_in)
	var minutes: int = rounded_time/60
	var seconds = rounded_time - (minutes*60)
	if seconds < 10:
		seconds = str(0) + str(seconds)
	return str(minutes,":",seconds)

"""
/*
* @pre Called when the timer hits 0
* @post Changes scene to minigame
* @param None
* @return String (text of current time left)
*/
"""
func _on_Timer_timeout():
	Global.reset_minigame_players()
	Global.state = Global.scenes.CAVE

func chatbox_use(value):
	if value:
		in_menu = true

"""
/*
* @pre Called in ready function before minigame
* @post Initalizes itemarray to 0s also positions hints randomly
* @param None
* @return None
*/
"""

func init_hiddenitems():
	hintlength=hint.length()
	answerlength=answer.length()
	lettersleft=answer.length()
	for i in 6:
		itemarray.append(0)
	# get hints
	var hints= get_tree().get_nodes_in_group("hints")
	var map=riddlemap.instance()
	var temppos=0
	var x=0
	var y=0
	#Create array of tile positions
	
	for i in 169:
		var tilepath="GridContainer/"+str(i+1)
		#print(tilepath)
		temppos=map.get_node(tilepath).rect_position
		var tempx=temppos.x+144
		var tempy=temppos.y+144
		tilepositionsx.append(tempx)
		tilepositionsy.append(tempy)
	#for loop to position hints

		#generate random tile for placement
	for i in 169:
		if i>=27 and i<=37:
			validtiles.append(i)
		elif i>=40 and i<=50:
			validtiles.append(i)
		elif i>=53 and i<=63:
			validtiles.append(i)
		elif i>=66 and i<=76:
			if i!=73 and i!=67 and i!=68 and i!=69:
				validtiles.append(i)
		elif i>=79 and i<=89:
			if i!=80 and i!=81 and i!=82 and i!=88:
				validtiles.append(i)
		elif i>=92 and i<=102:
			validtiles.append(i)
		elif i>=105 and i<=115:
			validtiles.append(i)
		elif i>=118 and i<=128:
			validtiles.append(i)
		elif i>=131 and i<=141:
			validtiles.append(i)
			
	print(validtiles.has(132))
	print(validtiles.has(130))
	
	for local_hint in hints:
		var tile=1000
		var rng = RandomNumberGenerator.new() 
		while validtiles.has(tile)==false: # if tile position not valid regenerate
			rng.randomize()
			tile=rng.randi_range(0, 169)
			#print(tile)
		#print(tile)
		x=tilepositionsx[tile]-400
		y=tilepositionsy[tile]-450
		#print(x)
		#print(y)
		local_hint.position = Vector2(x,y)
	
	$item1area.position=$item1.position
	$item2area.position=$item2.position
	$item3area.position=$item3.position
	$item4area.position=$item4.position
	$item5area.position=$item5.position
	$item6area.position=$item6.position
	
"""
/*
* @pre Called when player finds hidden item
* @post If item hasn't been found gives player letters for hint
* @param Player
* @return None
*/
"""
func enterarea(spritepath,itemnumber):
	$Player/Labelarea.hide()
	if itemarray[itemnumber-1]==0: #means item has not been found
		spritepath.show()
		var p_num = ServerConnection._player_num if ServerConnection.match_exists() else 1
		GameLoot.add_to_coin(p_num,3)
		var total_coin = GameLoot.get_coin_val(p_num)
		GlobalSignals.emit_signal("money_screen_val", total_coin)
		PlayerInventory.add_item("Coin", 3)
		var letter; # single letters found
		var letters=""; # string of letters if mutiple letter hint
		var lettercount=1;#keeps track so we don't return more than 2 letters
		if(answerlength>=6):
			while(lettersleft>=itemsleft and lettercount<=2):
				randomize()
				var random=hintlength-1;
				var index
				if(random!=0):
					index = randi() % random #generates random index for letter
				else:
					index=0
				letter=hint[index];#get random letter
				letters=letters+str(letter);# add letter to hints
				lettercount+=1;#update lettercount
				lettersleft=lettersleft-1;#update letters left that can be given
				#erases letter from hint so it cannot be given again
				hint.erase(index,1)
				if hintlength!=0:#checks if any letters left in hint
					hintlength=hintlength-1;#hintlength decreased as one letter given as hint
		else:
			randomize()
			var random=hintlength-1;
			var index
			if random!=0:
				index = randi() % random
			else:
				index=0
			letter=hint[index];
			letters=letters+str(letter);# add letter
			#erases letter from hint so it cannot be given again
			hint.erase(index,1)
			if hintlength!=0:
				hintlength=hintlength-1;#hintlength decreased as one letter given as hint
		currenthints=str(currenthints)+letters;
		$Player/Hints.text += "" + letters
		if hintlength==0:
			hintbox.window_title=str(letters)+" is in the word. All hints have been found."; #all hints found
		else:
			hintbox.window_title=str(letters)+" is in the word"; #sets hint to letter given
		hintbox.popup()
		itemsleft=itemsleft-1;#one item has been found
		itemarray[itemnumber-1]=1; #item has been found

"""
/*
* @pre Called when player enters hidden item area function declared for all 6 items
* @post If item hasn't been found alerts player item is nearby
* @param Player
* @return None
*/
"""
func _on_item1area_body_entered(_body:PhysicsBody2D)->void:
	if itemarray[0]==0 and answerlength>=1:
		$Player/Labelarea.show()
func _on_item2area_body_entered(_body:PhysicsBody2D)->void:
	if itemarray[1]==0 and answerlength>=2:
		$Player/Labelarea.show()
func _on_item3area_body_entered(_body:PhysicsBody2D)->void:
	if itemarray[2]==0 and answerlength>=3:
		$Player/Labelarea.show()
func _on_item4area_body_entered(_body:PhysicsBody2D)->void:
	if itemarray[3]==0 and answerlength>=4:
		$Player/Labelarea.show()
func _on_item5area_body_entered(_body:PhysicsBody2D)->void:
	if itemarray[4]==0 and answerlength>=5:
		$Player/Labelarea.show()
func _on_item6area_body_entered(_body:PhysicsBody2D)->void:
	if itemarray[5]==0 and answerlength>=6:
		$Player/Labelarea.show()
"""
/*
* @pre Called when player exits area near item called for all 6 items
* @post Hides message alerting player they are near item
* @param Player
* @return None
*/
"""
func _on_item1area_body_exited(_body:PhysicsBody2D)->void:
	$Player/Labelarea.hide()
	
func _on_item2area_body_exited(_body:PhysicsBody2D)->void:
	$Player/Labelarea.hide()
	
func _on_item3area_body_exited(_body:PhysicsBody2D)->void:
	$Player/Labelarea.hide()
	
func _on_item4area_body_exited(_body:PhysicsBody2D)->void:
	$Player/Labelarea.hide()
	
func _on_item5area_body_exited(_body:PhysicsBody2D)->void:
	$Player/Labelarea.hide()
	
func _on_item6area_body_exited(_body:PhysicsBody2D)->void:
	$Player/Labelarea.hide()
	
"""
/*
* @pre Called when player finds hidden item called for all 6 items
* @post Hides hidden item area label and shows hidden item along with alerting the player they have found the item
* @param Player
* @return None
*/
"""
func _on_item1_body_entered(_body:PhysicsBody2D)->void:
	if itemarray[0]==0 and answerlength>=1:
		enterarea($item1/AnimatedSprite,1)
		get_node("item1/AnimatedSprite").playing=true
		get_node("item1/AnimatedSprite").frame=0
		item = ItemClass.instance()
		

func _on_item2_body_entered(_body:PhysicsBody2D)->void:
	if itemarray[1]==0 and answerlength>=2:
		enterarea($item2/AnimatedSprite,2)
		get_node("item2/AnimatedSprite").playing=true
		get_node("item2/AnimatedSprite").frame=0
		item = ItemClass.instance()
		

func _on_item3_body_entered(_body:PhysicsBody2D)->void:
	if itemarray[2]==0 and answerlength>=3:
		enterarea($item3/AnimatedSprite,3)
		get_node("item3/AnimatedSprite").playing=true
		get_node("item3/AnimatedSprite").frame=0
		item = ItemClass.instance()
		

func _on_item4_body_entered(_body:PhysicsBody2D)->void:
	if itemarray[3]==0 and answerlength>=4:
		enterarea($item4/AnimatedSprite,4)
		get_node("item4/AnimatedSprite").playing=true
		get_node("item4/AnimatedSprite").frame=0
		item = ItemClass.instance()
		

func _on_item5_body_entered(_body:PhysicsBody2D)->void:
	if itemarray[4]==0 and answerlength>=5:
		enterarea($item5/AnimatedSprite,5)
		get_node("item5/AnimatedSprite").playing=true
		get_node("item5/AnimatedSprite").frame=0
		item = ItemClass.instance()
		

func _on_item6_body_entered(_body:PhysicsBody2D)->void:
	if itemarray[5]==0 and answerlength>=6:
		enterarea($item6/AnimatedSprite,6)
		get_node("item6/AnimatedSprite").playing=true
		get_node("item6/AnimatedSprite").frame=0
		item = ItemClass.instance()
		

"""
/*
* @pre Called when player has found item and is leaving called for all 6 items
* @post Hides hidden item  and label so they aren't shown again
* @param Player
* @return None
*/
"""
func _on_item1_body_exited(_body:PhysicsBody2D)->void:
	$item1/AnimatedSprite.hide()
	hintbox.hide()
func _on_item2_body_exited(_body:PhysicsBody2D)->void:
	$item2/AnimatedSprite.hide()
	hintbox.hide()
func _on_item3_body_exited(_body:PhysicsBody2D)->void:
	$item3/AnimatedSprite.hide()
	hintbox.hide()
func _on_item4_body_exited(_body:PhysicsBody2D)->void:
	$item4/AnimatedSprite.hide()
	hintbox.hide()
func _on_item5_body_exited(_body:PhysicsBody2D)->void:
	$item5/AnimatedSprite.hide()
	hintbox.hide()
func _on_item6_body_exited(_body):
	$item6/AnimatedSprite.hide()
	hintbox.hide()

"""
/*
* @pre called when players need to be spawned in (assuming server is online)
* @post Spawns players that move with server input and sets position regular player
* @param None
* @return None
*/
"""
func spawn_players():
	set_init_player_pos()
	#num_str = player number (1,2,3,4)
	for num_str in Global.player_positions:
		#Add animated player to scene
		var num = int(num_str)
		#if player is YOUR player (aka player you control)
		if num == ServerConnection._player_num:
			player_one.position = Global.player_positions[str(num)]
			player_one.set_color(num)
		#if the player is another online player
		else:
			var new_player:KinematicBody2D = load(other_player).instance()
			new_player.set_player_id(num)
			new_player.set_color(num)
			#Change size and pos of sprite
			new_player.position = Global.player_positions[str(num)]
			#Add child to the scene
			add_child(new_player)
		#Set initial input vectors to zero
		Global.player_input_vectors[str(num)] = Vector2.ZERO

"""
/*
* @pre None
* @post Sets players to intial positions by cave entrance
* @param None
* @return None
*/
"""
func set_init_player_pos():
	#num_str is the player number (1,2,3,4)
	for num_str in Global.player_positions:
		var num = int(num_str)
		match num:
			1: Global._player_positions_updated(num,Vector2(800,1350))
			2: Global._player_positions_updated(num,Vector2(880,1350))
			3: Global._player_positions_updated(num,Vector2(800,1250))
			4: Global._player_positions_updated(num,Vector2(880,1250))
			_: printerr("THERE ARE MORE THAN 4 PLAYERS TRYING TO BE SPAWNED IN riddleGame.gd")

#for chest
