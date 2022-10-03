extends KinematicBody
class_name Player
func get_class(): return 'Player'

onready var animation_tree := $'%AnimationTree' as AnimationTree
onready var area_reach := $'%AreaReach' as Area

export var use_input := false

export var anim_parrying := false

var ctl_move := Vector2.ZERO
var ctl_jump_held := false
var ctl_jump := false
var ctl_parry := false
var ctl_stab := false

var velocity := Vector3.ZERO


func stab() -> void:
	var hits := []
	for body in area_reach.get_overlapping_bodies():
		assert(body != self, 'hit self')
		var them := body as Player
		assert(them != null, 'hit unknown %s' % body)
		if them.parry(self):
			animation_tree['parameters/playback'].travel('damage')
			return # interrupt attack before damage goes through
		hits.append(them)
	for them in hits:
		them.damage(self)


func parry(from: Player) -> bool:
	if anim_parrying:
		print('%s parry attack from %s' % [name, from.name])
		animation_tree['parameters/parry/recoil/active'] = true
		return true
	else:
		return false


func damage(from: Player) -> void:
	print('%s took damage from %s' % [name, from.name])
	animation_tree['parameters/playback'].travel('damage')


func set_controls_from_input() -> void:
	ctl_move = Input.get_vector('move_left', 'move_right', 'move_down', 'move_up')
	ctl_jump_held = Input.is_action_pressed('move_jump')
	ctl_jump = Input.is_action_just_pressed('move_jump')
	ctl_parry = Input.is_action_just_pressed('combat_parry')
	ctl_stab = Input.is_action_just_pressed('combat_stab')


const PARAM_PLAYBACK = 'parameters/playback'
const PARAM_WALK_BLEND = 'parameters/move/walk/blend_position'
const PARAM_JUMP_ACTIVE = 'parameters/move/jump/active'
const PARAM_PARRY_RECOIL = 'parameters/parry/recoil/active'


func _physics_process(delta:float) -> void:
	if use_input:
		set_controls_from_input()

	var playback_state := animation_tree[PARAM_PLAYBACK] as AnimationNodeStateMachinePlayback
	var walk_blend := animation_tree[PARAM_WALK_BLEND] as float

	var can_attack := is_on_floor() \
		and not animation_tree[PARAM_JUMP_ACTIVE] as bool \
		and playback_state.get_current_node() == 'move' \
		and playback_state.get_travel_path().empty()

	if can_attack:
		walk_blend = lerp(walk_blend, ctl_move.x, TAU * delta)
		if ctl_jump:
			animation_tree[PARAM_JUMP_ACTIVE] = true
		elif ctl_parry:
			playback_state.travel('parry')
			animation_tree[PARAM_PARRY_RECOIL] = false
		elif ctl_stab:
			playback_state.travel('stab')
		else:
			animation_tree[PARAM_WALK_BLEND] = walk_blend

	var	root_motion := animation_tree.get_root_motion_transform()
	var linear_motion := transform.basis * root_motion.origin / delta

	# Angular motion
	# transform.basis *= root_motion.basis
	if can_attack:
		if walk_blend > 0.0: rotation.y = PI/2
		if walk_blend < 0.0: rotation.y = -PI/2

	# Linear motion
	if is_on_floor():
		velocity = linear_motion
		velocity.y -= 10.0 * delta

	elif linear_motion.y <= 0.0:
		velocity.x = PI * walk_blend
		velocity.y -= 10.0 * delta
	else:
		velocity.x = PI * walk_blend
		velocity.y = linear_motion.y

	# var snap := Vector3.ZERO if animation_tree['parameters/move/jump/active'] else Vector3.DOWN
	# velocity = move_and_slide_with_snap(velocity, snap, Vector3.UP)
	velocity = move_and_slide(velocity, Vector3.UP)

	# Rails, just to be sure
	translation.z = 0.0
	velocity.z = 0.0
