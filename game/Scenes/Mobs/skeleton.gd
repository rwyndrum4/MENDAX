extends KinematicBody2D
onready var skeletonAnim = $AnimationPlayer
onready var healthbar = $ProgressBar
onready var skeleBox = $MyHurtBox/hitbox
onready var skeleAtkBox = $MyHitBox/CollisionShape2D

var isIn = false
var isDead = 0


func _ready():
	var anim = get_node("AnimationPlayer").get_animation("idle")
	anim.set_loop(true)
	skeletonAnim.play("idle")
	healthbar.value = 100;

func take_damage(amount: int) -> void:
	
	healthbar.value = healthbar.value - amount
	skeletonAnim.play("hit")
	print(healthbar.value)
	if healthbar.value == 0:
		skeletonAnim.play("death")
		skeleBox.disabled = true
		isDead = 1
		
	



func _on_AnimationPlayer_animation_finished(anim_name):
		
	if !isDead:
		if !isIn:			
			skeletonAnim.play("idle")
		else:
			skeletonAnim.play("attack1")
	else:
		queue_free()


func _on_detector_body_entered(body):
	isIn = true
	skeletonAnim.play("attack1")
	



func _on_detector_body_exited(body):
	isIn = false
