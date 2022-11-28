"""
* Programmer Name - Freeman Spray and Mohit Garg
* Description - Code for controlling the Riddle minigame
* Date Created - 10/14/2022
* Date Revisions:
	10/16/2022 - 
	10/19/2022 -Added hidden item detector functionality -Mohit Garg
	10/22/2022-Added hidden item detector for multiple hints-Mohit Garg
"""
extends Control

# Member Variables
var in_menu = false
onready var myTimer: Timer = $GUI/Timer
onready var timerText: Label = $GUI/Timer/timerText
onready var textBox = $GUI/textBox
onready var hintbox=$GUI/show_letter
onready var itemarray=[] #determines if items have been found
onready var hint="";# set in init riddle
var answer = ""#set in init riddle
onready var riddle="";#set in init riddle
onready var riddlefile = 'res://Assets/riddle_jester/riddles.txt'
var riddle_dict = {} #stores riddles and their answers
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

#Scene for players that online oppenents use
var other_player = "res://Scenes/player/other_players/other_players.tscn"

#Inventory changes - perhaps this should move somewhere more general
var item = null
var ItemClass = preload("res://Inventory/Item.tscn")
onready var inv = get_node("/root/global/")

#signals
signal textWait()
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
	var err=f.open(file, File.READ)
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
		#print(number)
		riddle= str(riddle_dict[number])
		hint=str(riddle_dict[number+1])
		answer=hint
	
"""
/*
* @pre Called when the node enters the scene tree for the first time.
* @post updates starts the timer
* @param file
* @return None
*/
"""
func _ready():
	# warning-ignore:return_value_discarded
	GlobalSignals.connect("answer_received",self,"_check_answer")
	# warning-ignore:return_value_discarded
	ServerConnection.connect( "riddle_received", self, "set_riddle_from_server")
	#myTimer.start(90)
	init_playerpos=$Player.position
	# warning-ignore:return_value_discarded
	GlobalSignals.connect("openChatbox", self, "chatbox_use")
	if ServerConnection.match_exists():
		spawn_players()
		if ServerConnection._player_num != 1:
			yield(self, "riddle_received_from_server")
	#scene animation for entering cave(for first time)
	if Global.entry == 0:
	#Insert Dialogue: "Oh who do we have here?" or something similar
		var t = Timer.new()
		t.set_wait_time(1)
		t.set_one_shot(false)
		self.add_child(t)
		Global.entry = 1
		transCam.current = true
		$Player.set_physics_process(false)
		#Begin scene dialogue
		textBox.queue_text("Oh who do we have here?")
		t.start()
		yield(t, "timeout")
		t.queue_free()
		$Path2D/AnimationPlayer.play("BEGIN")
		yield($Path2D/AnimationPlayer, "animation_finished")
		#This is how you queue text to the textbox queue
		textBox.queue_text("In order to pass you must solve this riddle...")
		init_riddle(riddlefile) #initalizes riddle randomly
		init_hiddenitems() #initalizes hidden items array and other things needed
		#textBox.queue_text("What walks on four legs in the morning, two legs in the afternoon, and three in the evening?")
		textBox.queue_text(riddle)
		textBox.queue_text("Please enter the answer in the chat once you have it, there are hints hidden here if you need them (:")
		# warning-ignore:return_value_discarded
		connect("textWait", self, "_finish_anim")
		Global.in_anim = 1;
	else:
		myTimer.start(90)

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
* @pre An input of any sort
* @post None
* @param Takes in an event
* @return None
*/
"""
func _input(ev):
	if Input.is_key_pressed(KEY_ENTER) and not ev.echo and textBox.queue_text_length() == 0:
		if Global.in_anim == 1:
			Global.in_anim = 0
			emit_signal("textWait")
	if Input.is_key_pressed(KEY_SEMICOLON):
		PlayerInventory.add_item("Coin", 1)
	#DEBUG PURPOSES - REMOVE FOR FINAL GAME!!!
	#IF YOU PRESS P -> TIMER WILL REDUCE TO 3 SECONDS
	if Input.is_action_just_pressed("timer_debug_key",false):
		myTimer.start(3)
	#IF YOU PRESS Q -> TIMER WILL INCREASE TO ARBITRARILY MANY SECONDS
	if Input.is_action_just_pressed("extend_timer_debug_key",false):
		myTimer.start(30000)

"""
/*
* @pre Called when someone guesses an answer
* @post Leaves scene if they guess right
* @param answer -> String
* @return None
*/
"""
func _check_answer(answer_in:String):
	if answer == answer_in:
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
	Global.state = Global.scenes.CAVE

func chatbox_use(value):
	if value:
		in_menu = true

"""
/*
* @pre Called in ready function before minigame
* @post Initalizes itemarray to 0s indicating no items have been found places hints randomly so there is no overlap
* @param None
* @return None
*/
"""
func init_hiddenitems():
	hintlength=hint.length()
	print(hintlength)
	answerlength=answer.length()
	lettersleft=answer.length()
	for i in 6:
		itemarray.append(0)
	#initalizing 2d overlap arrays for x and y 7 rows and 2 entries per each row
	for i in range(0,7):
		x_overlap.append([])
		y_overlap.append([])
		for j in range(0,2):
			x_overlap[i].append(0)
			y_overlap[i].append(0)
	x_overlap[0][0]=init_playerpos.x-10; #left endpoint of player_pos
	x_overlap[0][1]=init_playerpos.x+10;# right endpoint of player_pos
	y_overlap[0][0]=init_playerpos.y-10;
	y_overlap[0][1]=init_playerpos.y+10;
	#need to randomize locations of hidden hints
	var hints= get_tree().get_nodes_in_group("hints")
	
	var hintcounter=1 #helps keep track of hints in for loop
	var overlap;#1 if overlap found in for loop 2 if overlap found
	var x;
	var y;
	for hint in hints:
		overlap=1
		while overlap==1:
			x=rand_range(0, 3000) #range of game map reduced  due to size of hint area
			y=rand_range(0,3000)#range of game map reduced  due to size of hint area
			for i in range(0, hintcounter):
				if ((x+150)>=x_overlap[i][0] or (x-150)<=x_overlap[i][1]) and ((y+150)>=y_overlap[i][0] or (y-150)<=y_overlap[i][1]): #overlap in both x and y direcitons indicates overlap
					overlap=2
			#logic below makes loop behave like do while will break if  overlap not found
			if overlap==2:
				overlap=1
			if overlap==1:
				overlap=2 
				
		hint.position = Vector2(x,y)
		#set overlaps for hint using hintcounter
		x_overlap[hintcounter][0]=x-150; #left endpoint of hint area box
		x_overlap[hintcounter][1]=x+150;# right endpoint of hint area box
		y_overlap[hintcounter][0]=init_playerpos.y-150;
		y_overlap[hintcounter][1]=init_playerpos.y+150;
		#print(hint.position)
		hintcounter=hintcounter+1
	$item1area.position=$item1.position
	$item2area.position=$item2.position
	$item3area.position=$item3.position
	$item4area.position=$item4.position
	$item5area.position=$item5.position
	$item6area.position=$item6.position
		

"""
/*
* @pre Called when player find hidden item
* @post If item hasn't been found gives player letters for hint
* @param Player
* @return None
*/
"""
func enterarea(spritepath,itemnumber):
	$Player/Labelarea.hide()
	if itemarray[itemnumber-1]==0: #means item has not been found
		spritepath.show()
		var letter; # single letters found
		var letters=""; # string of letters if mutiple letter hint
		var lettercount=1;#keeps track so we don't return more than 2 letters
		if(answerlength>=6):
			while(lettersleft>=itemsleft and lettercount<=2):
				randomize()
				#print(hintlength)
				var random=hintlength-1;
				var index
				if(random!=0):
					index = randi() % random #generates random index for letter
				else:
					index=0
				letter=hint[index];#get random letter
				#print(index)
				letters=letters+str(letter);# add letter to hints
				lettercount+=1;#update lettercount
				lettersleft=lettersleft-1;#update letters left that can be given
				#erases letter from hint so it cannot be given again
				hint.erase(index,1)
				if hintlength!=0:#checks if any letters left in hint
					hintlength=hintlength-1;#hintlength decreased as one letter given as hint
				#print(letters)
				#print(hint)
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
* @pre Called when you received riddle from other player
* @post Set the riddle and answer
* @param riddle_in -> String, answer_in -> String
* @return None
*/
"""
func set_riddle_from_server(riddle_in:String, answer_in:String) -> void:
	riddle = riddle_in
	hint = riddle_in
	answer = answer_in
	emit_signal("riddle_received_from_server")

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
		enterarea($item1/Sprite,1)
		
		textBox.queue_text("MONEY!!")
func _on_item2_body_entered(_body:PhysicsBody2D)->void:
	if itemarray[1]==0 and answerlength>=2:
		enterarea($item2/Sprite,2)
		item = ItemClass.instance()
		
		textBox.queue_text("MONEY!!")
func _on_item3_body_entered(_body:PhysicsBody2D)->void:
	if itemarray[2]==0 and answerlength>=3:
		enterarea($item3/Sprite,3)
		item = ItemClass.instance()
		
		textBox.queue_text("MONEY!!")
func _on_item4_body_entered(_body:PhysicsBody2D)->void:
	if itemarray[3]==0 and answerlength>=4:
		enterarea($item4/Sprite,4)
		item = ItemClass.instance()
		
		textBox.queue_text("MONEY!!")
func _on_item5_body_entered(_body:PhysicsBody2D)->void:
	if itemarray[4]==0 and answerlength>=5:
		enterarea($item5/Sprite,5)
		item = ItemClass.instance()
		
		textBox.queue_text("MONEY!!")
func _on_item6_body_entered(_body:PhysicsBody2D)->void:
	if itemarray[5]==0 and answerlength>=6:
		enterarea($item6/Sprite,6)
		item = ItemClass.instance()
		
		textBox.queue_text("MONEY!!")
"""
/*
* @pre Called when player has found item and is leaving called for all 6 items
* @post Hides hidden item  and label so they aren't shown again
* @param Player
* @return None
*/
"""
func _on_item1_body_exited(_body:PhysicsBody2D)->void:
	$item1/Sprite.hide()
	hintbox.hide()
func _on_item2_body_exited(_body:PhysicsBody2D)->void:
	$item2/Sprite.hide()
	hintbox.hide()
func _on_item3_body_exited(_body:PhysicsBody2D)->void:
	$item3/Sprite.hide()
	hintbox.hide()
func _on_item4_body_exited(_body:PhysicsBody2D)->void:
	$item4/Sprite.hide()
	hintbox.hide()
func _on_item5_body_exited(_body:PhysicsBody2D)->void:
	$item5/Sprite.hide()
	hintbox.hide()
func _on_item6_body_exited(_body):
	$item6/Sprite.hide()
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
