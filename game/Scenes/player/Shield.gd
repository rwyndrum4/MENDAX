extends Sprite

const INVINCIBILITY_TIME = 0.5
var durability = 0
onready var shieldTimer = $ShieldDelay

var FullShield = preload("res://Assets/shieldFull.png")
var SomeDamage = preload("res://Assets/shieldLightDamage.png")
var CrackedShield = preload("res://Assets/shieldCracked.png")

func isUp():
	return durability > 0

func refreshTexture():
	if durability > 4:
		visible = true
		set_texture(FullShield)
	elif durability > 2:
		set_texture(SomeDamage)
	elif durability > 0:
		set_texture(CrackedShield)
	else:
		visible = false
	return

func giveShield():
	durability = 6
	refreshTexture()
	return

func takeDamage():
	if !shieldTimer.is_stopped():
		return
	shieldTimer.start(INVINCIBILITY_TIME)
	durability -= 1
	refreshTexture()


# Called when the node enters the scene tree for the first time.
func _ready():
	visible = false
	shieldTimer
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
