extends KinematicBody2D
onready var skeleton = $Position2D/AnimatedSprite
onready var healthbar = $ProgressBar
onready var skeleBox = $MyHurtBox/hitbox
var isDead = 0


func _ready():
	skeleton.play("idle")
	healthbar.value = 100;

func take_damage(amount: int) -> void:
	
	healthbar.value = healthbar.value - amount
	skeleton.play("hit")
	print(healthbar.value)
	if healthbar.value == 0:
		skeleton.play("death")
		skeleBox.disabled = true
		isDead = 1
		
		
		
	
	
	


func _on_AnimatedSprite_animation_finished():
	
	if !isDead:
		skeleton.play("idle")
	else:
		queue_free()
