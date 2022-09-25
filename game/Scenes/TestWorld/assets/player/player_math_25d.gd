# Handles Player-specific behavior like moving. We calculate such things with KinematicBody.
extends KinematicBody
class_name PlayerMath25D # No icon necessary

var vertical_speed := 0.0
var isometric_controls := true
onready var _parent_node25d: Node25D = get_parent()

func _process(delta):
	if Input.is_action_pressed("exit"):
		get_tree().quit()

	if Input.is_action_just_pressed("view_cube_demo"):
		#warning-ignore:return_value_discarded
		get_tree().change_scene("res://assets/cube/cube.tscn")
		return

	if Input.is_action_just_pressed("toggle_isometric_controls"):
		isometric_controls = not isometric_controls
	if Input.is_action_just_pressed("reset_position"):
		transform = Transform(Basis(), Vector3.UP * 10)
		vertical_speed = 0
	else:
		_horizontal_movement(delta)
		_vertical_movement(delta)


# Checks WASD and Shift for horizontal movement via move_and_slide.
func _horizontal_movement(delta):
	var localX = Vector3.RIGHT
	var localZ = Vector3.BACK

	if isometric_controls and is_equal_approx(Node25D.SCALE * 0.86602540378, _parent_node25d.get_basis()[0].x):
		localX = Vector3(0.70710678118, 0, -0.70710678118)
		localZ = Vector3(0.70710678118, 0, 0.70710678118)

	# Gather player input and add directional movement to a Vector3 variable.
	var movement_vec2 = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var move_dir = localX * movement_vec2.x + localZ * movement_vec2.y

	move_dir = move_dir * delta * 600
	if Input.is_action_pressed("movement_modifier"):
		move_dir /= 2

	#warning-ignore:return_value_discarded
	move_and_slide(move_dir)


# Checks Jump and applies gravity and vertical speed via move_and_collide.
func _vertical_movement(delta):
	var localY = Vector3.UP
	if Input.is_action_just_pressed("jump"):
		vertical_speed = 1.25
	vertical_speed -= delta * 5 # Gravity
	var k = move_and_collide(localY * vertical_speed)
	if k != null:
		vertical_speed = 0
