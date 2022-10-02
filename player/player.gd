extends KinematicBody
class_name Player
func get_class(): return 'Player'

onready var animation_tree := $AnimationTree as AnimationTree
onready var stick_anim := $StickAnim as AnimationPlayer
onready var reach := $Reach as Area

export var input_enabled := false

var ctl_move := Vector2.ZERO
var ctl_jump_held := false
var ctl_jump := false
var ctl_parry := false
var ctl_stab := false

var param_walk_blend := 0.0

var velocity := Vector3.ZERO


func on_stab() -> void:
	var hits := []
	for body in reach.get_overlapping_bodies():
		var them := body as Player
		assert(them != self, 'hit self')
		assert(them != null, 'hit unexpected body (%s)' % body)
		hits.append(them)
		if them.stick_anim.is_playing() and them.stick_anim.current_animation == 'Parry':
			them.stick_anim.play('ParryRecoil')
			self.stick_anim.play('StabRecoil')
			return
	for them in hits:
		print('%s recv_damage' % [them.name])
		them.stick_anim.play('ParryRecoil', -1, 0.5) # slowed 50%
	stick_anim.play('StabPull')


func set_controls_from_input() -> void:
	ctl_move = Input.get_vector('move_left', 'move_right', 'move_down', 'move_up')
	ctl_jump_held = Input.is_action_pressed('move_jump')
	ctl_jump = Input.is_action_just_pressed('move_jump')
	ctl_parry = Input.is_action_just_pressed('combat_parry')
	ctl_stab = Input.is_action_just_pressed('combat_stab')


func _physics_process(delta:float) -> void:
	if input_enabled:
		set_controls_from_input()

	if ctl_parry and not stick_anim.is_playing():
		stick_anim.play('Parry')
	elif ctl_stab and not stick_anim.is_playing():
		stick_anim.play('Stab')

	# animation_tree['parameters/playback'].travel('walk')
	param_walk_blend = lerp(param_walk_blend, ctl_move.x, TAU * delta)
	animation_tree['parameters/walk/blend_position'] = param_walk_blend

	var	root_motion := animation_tree.get_root_motion_transform()
	# transform.basis *= root_motion.basis
	if param_walk_blend > 0.0: rotation.y = PI/2
	if param_walk_blend < 0.0: rotation.y = -PI/2
	velocity = transform.basis * root_motion.origin / delta
	var snap := Vector3.ZERO if ctl_jump_held else Vector3.DOWN
	velocity = move_and_slide_with_snap(velocity, snap, Vector3.UP)


# NOTE: For game logic, AnimationPlayer.playback_process_mode should be ANIMATION_PROCESS_PHYSICS.
# NOTE: _physics_process() happens in scene tree order, i.e. parent > child1 > child2.
func _on_Stick_animation_finished(anim_name:String) -> void:
	match anim_name:
		'Stab':
			on_stab()
