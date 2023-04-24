"""
* Programmer Name - Jason Truong
* Description - Code that designates mob animations
* Date Created - 11/20/2022
* Date Revisions: - 11/28/2022 - add death signal
"""
extends KinematicBody2D
onready var BodAnim = $AnimationPlayer
onready var healthbar = $ProgressBar
onready var BodBox = $MyHurtBox/hitbox
onready var BodAtkBox = $MyHitBox/CollisionShape2D
onready var pos2d = $Position2D
onready var player_detector_box = $detector/box

var _has_spawned = false
var _leveled_up = false
var _name = "b"
var _my_id: int = 0
var _can_atk = true
var isIn: bool = false
var isDead:bool = false
var teleport_timer:Timer = null

"""
/*
* @pre Called once when mob is initialized
* @post Makes idle animation loop and initializes the health
* @param None
* @return None
*/
"""
func _ready():
	set_meta("enemy_name","BoD")
	_has_spawned = true
	if _leveled_up:
		level_up()
	var anim = get_node("AnimationPlayer").get_animation("idle")
	anim.set_loop(true)
	BodAnim.play("idle")
	healthbar.value = 200;
	# warning-ignore:return_value_discarded
	GlobalSignals.connect("textbox_empty",self,"turn_on_physics")


"""
/*
* @pre Called every frame
* @post x an y velocity of the Skeleton is updated to move towards the player (if the player is within it's Search range)
* @param delta : elapsed time (in seconds) since previous frame. Should be constant across sequential calls
* @return None
*/
"""		
func _physics_process(_delta):
	var player_pos = null
	if not get_parent()._player_dead:
		player_pos = get_parent().get_node("Player").position
	else:
		return
	#Handle making skeleton turn around
	if player_pos.x < position.x:
		pos2d.scale.x = 1
		player_detector_box.position = Vector2(-70,-6)
		BodAtkBox.position = Vector2(-135,-3)
	else:
		pos2d.scale.x = -1
		player_detector_box.position = Vector2(70,-5)
		BodAtkBox.position = Vector2(5,-3)

"""
/*
* @pre Text Box queue is empty
* @post turns back on the physics process, aka can now move
* @param None
* @return None
*/
"""		
func turn_on_physics():
	set_physics_process(true)
	#Now that BoD can move, allow them to teleport
	teleport_timer= Timer.new()
	add_child(teleport_timer)
	teleport_timer.wait_time = 6
	teleport_timer.one_shot = false
	teleport_timer.start()
	# warning-ignore:return_value_discarded
	teleport_timer.connect("timeout",self, "_tp_timer_expired")

"""
/*
* @pre Called by when it detects a "hit" from a hitbox
* @post Mob takes damage and is reflected by the healthbar
* @param Takes in a damage value
* @return None
*/
"""
func take_damage(amount: int) -> void:
	$AudioStreamPlayer2D.play()
	ServerConnection.send_arena_enemy_hit(amount,_my_id, _name)
	healthbar.value = healthbar.value - amount
	
	Global.bod_damage[str(1)]+=amount
	if healthbar.value <= 0:
		isDead = true
		BodAnim.play("death")
		call_deferred("defer_disabling_BoD")

#Same as above function except it doesn't send data to server
func take_damage_server(amount: int):
	healthbar.value = healthbar.value - amount
	if healthbar.value <= 0:
		isDead = true
		BodAnim.play("death")
		call_deferred("defer_disabling_BoD")

#function for disabling skeleton, needs to be deferred for reasons above
func defer_disabling_BoD():
	BodBox.disabled = true

"""
/*
* @pre Called once animation is finished
* @post Dequeue's the mob if isDead is true otherwise plays an animation
* @param None
* @return None
*/
"""
func _on_AnimationPlayer_animation_finished(_anim_name):
	if !isDead:
		if !isIn:			
			BodAnim.play("idle")
		else:
			$atk.play()
			BodAnim.play("attack1")
			
	else:
		$death.play()
		yield($death, "finished")
		GlobalSignals.emit_signal("enemyDefeated", _my_id)
		queue_free()

"""
/*
* @pre Called when it detects a body entering its 2D area
* @post isIn is set to true
* @param None
* @return None
*/
"""
func _on_detector_body_entered(_body):
	isIn = true
	if not isDead and _can_atk:
		BodAnim.play("attack1")

"""
/*
* @pre Called once a body leaves the 2D area
* @post isIn is set to false
* @param None
* @return None
*/
"""
func _on_detector_body_exited(_body):
	isIn = false

"""
/*
* @pre timer in arenaGame has expired
* @post make BoD tougher
* @param None
* @return None
*/
"""
func level_up():
	_leveled_up = true
	healthbar.value = healthbar.value + 40
	teleport_timer.wait_time = 4

"""
/*
* @pre timer defined above has expired
* @post makes BoD telport to player
* @param None
* @return None
*/
"""
func _tp_timer_expired():
	if isDead:
		return
	BodAnim.stop() #stop previous animation if it had one
	if not get_parent()._player_dead:
		randomize()
		var x = rand_range(25,80)
		var y = rand_range(25,80)
		if randf() > 0.5:
			x *= -1
			y *= -1
		if ServerConnection.match_exists() and ServerConnection.get_server_status():
			var server_players:Array = get_parent().server_players
			var total = Vector2.ZERO
			var ctr = 0
			for p in server_players:
				var obj = p.get('player_obj') 
				if is_instance_valid(obj):
					ctr += 1
					total += obj.position
			var your_pos = get_parent().get_node("Player").position
			total += your_pos
			position = check_pos(total / (ctr + 1))
		else:
			x *= 5
			y *= 5
			var final_pos = check_pos(get_parent().get_node("Player").position + Vector2(x,y))
			position = final_pos
		#Play animation to give player time to react
		_can_atk = false
		BodAnim.play("spellatk")
		yield(BodAnim,"animation_finished")
		_can_atk = true

func check_pos(pos2check:Vector2) -> Vector2:
	var HIGH = 3250
	var LOW = 500
	var result:Vector2 = pos2check
	if pos2check.x < LOW:
		result.x = 600
	elif pos2check.x > HIGH:
		result.x = 3000
	if pos2check.y < LOW:
		result.y = 600
	elif pos2check.y > HIGH:
		result.y = 3000
	return result

func set_id(id_num:int) -> void:
	_my_id = id_num

func get_id() -> int:
	return _my_id
