extends KinematicBody

const FACE_LEFT = Basis(Quat(Vector3(0, - PI + 0.01, 0)))
const FACE_RIGHT = Basis(Quat(Vector3(0, - 0.01, 0)))

onready var anim_player := $AnimationPlayer as AnimationPlayer

export(float, 1, 9) var move_speed := TAU
export(float, 1, 20) var move_scale := 12.0
export(float, 1, 20) var stop_scale := 15.0
export(float, 1, 3) var jump_height := 1.2
export(float, 1, 10) var jump_scale := PI
export(float, 1, 10) var fall_scale := PI * 3/2

var gravity : float = ProjectSettings.get_setting('physics/3d/default_gravity')
var velocity := Vector3.ZERO
var facing := Quat.IDENTITY
var swing_area_bodies := []


#
func _on_SwingArea_body_entered(body: Node) -> void:
	if body != self:
		swing_area_bodies.append(body)


#
func _on_SwingArea_body_exited(body: Node) -> void:
	swing_area_bodies.erase(body)


#
func _physics_process(delta):
	var input_move := Input.get_vector('move_left', 'move_right', 'move_down', 'move_up')
	var input_jump := Input.is_action_pressed('move_jump')
	var input_jump_now := Input.is_action_just_pressed('move_jump')
	var input_attack_primary := Input.is_action_just_pressed('attack_primary')

	# Player actions
	if input_attack_primary:
		if not anim_player.is_playing():
			anim_player.play('Swing')
			for body in swing_area_bodies:
				print('swing hit %s' % body)
				body.queue_free()

	# Horizontal movement
	if is_zero_approx(input_move.x):
		velocity.x = lerp(velocity.x, 0.0, stop_scale * delta)
	else:
		velocity.x = lerp(velocity.x, input_move.x * move_speed, move_scale * delta)
		facing = FACE_LEFT if input_move.x < 0.0 else FACE_RIGHT

	# Vertical movement
	var snap := Vector3.ZERO if input_jump else Vector3.DOWN
	if input_jump_now and is_on_floor():
		velocity.y += sqrt(2 * jump_height * gravity * jump_scale)
	elif input_jump and velocity.y > 0.0:
		velocity.y -= gravity * jump_scale * delta
	else:
		velocity.y -= gravity * fall_scale * delta

	# Apply movement
	transform.basis = transform.basis.slerp(facing, TAU * delta)
	velocity = move_and_slide_with_snap(velocity, snap, Vector3.UP)
