extends KinematicBody
class_name Player
func get_class(): return 'Player'

onready var animation_tree := $AnimationTree as AnimationTree
onready var game_logic := $GameLogic as AnimationPlayer
onready var reach := $Reach as Area

export var input_enabled := false
export var is_parrying := false

var ctl_move := Vector2.ZERO
var ctl_jump_held := false
var ctl_jump := false
var ctl_parry := false
var ctl_stab := false

var param_walk := 0.0
var velocity := Vector3.ZERO


func play_audio(name:String) -> void:
	match name:
		'Dash':
			$CueDash.play()
		'Parry':
			$CueParry.play()
		'Damaged':
			get_node('AudioDamaged%d' % [randi()%4+1]).play()
		'Death':
			get_node('AudioDeath%d' % [randi()%2+1]).play()
		'SwordBlocked':
			$AudioSwordBlocked.play()
		'SwordStab':
			$CueSwordStab.play()
		'SwordStabFlourish':
			$CueSwordStabFlourish.play()
		'SwordSwing':
			get_node('AudioSwordSwing%d' % [randi()%4+1]).play()
		_:
			push_error('play_audio %s' % name)


func on_attack() -> void:
	var hits := []
	for body in reach.get_overlapping_bodies():
		var them := body as Player
		assert(them != self, 'hit self')
		assert(them != null, 'hit unexpected body (%s)' % body)
		hits.append(them)
		if them.is_parrying:
			them.play_audio('Parry')
			self.play_audio('SwordBlocked')
			self.game_logic.play('Recoil', -1, 0.5)
			return
	for them in hits:
		print('%s recv_damage' % [them.name])
		them.play_audio('Damaged')
		them.game_logic.play('Recoil')


func set_controls_from_input() -> void:
	ctl_move = Input.get_vector('move_left', 'move_right', 'move_down', 'move_up')
	ctl_jump_held = Input.is_action_pressed('move_jump')
	ctl_jump = Input.is_action_just_pressed('move_jump')
	ctl_parry = Input.is_action_just_pressed('combat_parry')
	ctl_stab = Input.is_action_just_pressed('combat_stab')


func _physics_process(delta:float) -> void:
	if input_enabled:
		set_controls_from_input()

	var playback_state := animation_tree['parameters/playback'] as AnimationNodeStateMachinePlayback
	var is_walking := playback_state.get_current_node() == 'walk'

	if ctl_parry and is_walking:
		game_logic.play('Parry')
		animation_tree['parameters/playback'].travel('parry')
	elif ctl_stab and is_walking:
		game_logic.play('Attack')
		animation_tree['parameters/playback'].travel('stab')
	else:
		param_walk = lerp(param_walk, ctl_move.x, TAU * delta)
		animation_tree['parameters/walk/blend_position'] = param_walk
		animation_tree['parameters/playback'].travel('walk')

	var	root_motion := animation_tree.get_root_motion_transform()
	# transform.basis *= root_motion.basis
	if param_walk > 0.0: rotation.y = PI/2
	if param_walk < 0.0: rotation.y = -PI/2
	velocity = transform.basis * root_motion.origin / delta
	var snap := Vector3.ZERO if velocity.y > 0.0 else Vector3.DOWN
	velocity = move_and_slide_with_snap(velocity, snap, Vector3.UP)
