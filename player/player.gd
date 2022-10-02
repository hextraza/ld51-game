extends KinematicBody
class_name Player
func get_class(): return 'Player'

const FACE_LEFT = Basis(Quat(Vector3(0, - PI + 0.01, 0)))
const FACE_RIGHT = Basis(Quat(Vector3(0, - 0.01, 0)))

onready var anim := $AnimationPlayer as AnimationPlayer
onready var reach := $Reach as Area

export var input_enabled := false
export(float, 1, 9) var move_speed := TAU
export(float, 1, 20) var move_scale := 12.0
export(float, 1, 20) var stop_scale := 15.0
export(float, 1, 3) var jump_height := 1.2
export(float, 1, 10) var jump_scale := PI
export(float, 1, 10) var fall_scale := PI * 3/2
export(float, 0, 50) var recoil_speed := 25.0

var gravity : float = ProjectSettings.get_setting('physics/3d/default_gravity')
var velocity := Vector3.ZERO
var facing := Quat.IDENTITY

var ctl_move := Vector2.ZERO
var ctl_jump_held := false
var ctl_jump := false
var ctl_parry := false
var ctl_stab := false


#
func is_parrying() -> bool:
	return anim.is_playing() and anim.current_animation == 'Parry'


#
func on_stab() -> void:
	var hits := []

	for body in reach.get_overlapping_bodies():
		var them := body as Player
		if them == self: continue;
		assert(them != null, 'hit unexpected body (%s)' % body)
		hits.append(them)
		if them.is_parrying():
			var dir_x := sign(self.translation.x - them.translation.x)
			them.on_parry_recoil()
			self.on_stab_recoil(dir_x)
			return

	for body in hits:
		(body as Player).recv_damage()

	anim.play('StabPull')


#
func on_stab_recoil(dir_x: float) -> void:
	anim.play('StabRecoil')
	velocity.x += recoil_speed * dir_x # emulates weight


#
func on_parry_recoil() -> void:
	anim.play('ParryRecoil')


#
func recv_damage() -> void:
	print('%s recv_damage' % [name])
	anim.play('ParryRecoil', 0.1, 0.5) # slowed 50%
	velocity.x *= 0.5 # suppression, maybe


#
func set_controls_from_input() -> void:
	ctl_move = Input.get_vector('move_left', 'move_right', 'move_down', 'move_up')
	ctl_jump_held = Input.is_action_pressed('move_jump')
	ctl_jump = Input.is_action_just_pressed('move_jump')
	ctl_parry = Input.is_action_just_pressed('combat_parry')
	ctl_stab = Input.is_action_just_pressed('combat_stab')


#
func _physics_process(delta):
	if input_enabled:
		set_controls_from_input()

	if ctl_parry and not anim.is_playing():
		anim.play('Parry')

	if ctl_stab and not anim.is_playing():
		anim.play('Stab')

	# Horizontal movement
	if is_zero_approx(ctl_move.x):
		velocity.x = lerp(velocity.x, 0.0, stop_scale * delta)
	else:
		velocity.x = lerp(velocity.x, ctl_move.x * move_speed, move_scale * delta)
		facing = FACE_LEFT if ctl_move.x < 0.0 else FACE_RIGHT

	# Vertical movement
	var snap := Vector3.ZERO if ctl_jump_held else Vector3.DOWN
	if ctl_jump and is_on_floor():
		velocity.y += sqrt(2 * jump_height * gravity * jump_scale)
	elif ctl_jump_held and velocity.y > 0.0:
		velocity.y -= gravity * jump_scale * delta
	else:
		velocity.y -= gravity * fall_scale * delta

	# Apply movement
	transform.basis = transform.basis.slerp(facing, TAU * delta)
	velocity = move_and_slide_with_snap(velocity, snap, Vector3.UP)


# NOTE: For game logic, AnimationPlayer.playback_process_mode should be ANIMATION_PROCESS_PHYSICS.
# NOTE: _physics_process() happens in scene tree order, i.e. parent > child1 > child2.
func _on_animation_finished(anim_name:String) -> void:
	anim.playback_process_mode = AnimationPlayer.ANIMATION_PROCESS_PHYSICS
	match anim_name:
		'Stab':
			on_stab()
