extends KinematicBody
class_name Player
func get_class(): return 'Player'


const PARAM_PLAYBACK = 'parameters/playback'
const PARAM_WALK_BLEND = 'parameters/move/walk/blend_position'
const PARAM_JUMP_ACTIVE = 'parameters/move/jump/active'
const PARAM_PARRY_RECOIL = 'parameters/parry/recoil/active'

onready var animation_tree := $'%AnimationTree' as AnimationTree
onready var area_reach := $'%AreaReach' as Area

export var use_input := false
export var parry_dash := 25.0

export var _parrying := false
export var _dash_invuln := false
export var _dash_amount := 0.0

var ctl_move := Vector2.ZERO
var ctl_jump_held := false
var ctl_jump := false
var ctl_parry := false
var ctl_stab := false
var ctl_dash := false

var velocity := Vector3.ZERO


func stab() -> void:
	var hits := []
	for body in area_reach.get_overlapping_bodies():
		assert(body != self, 'hit self')
		var them := body as Player
		if them.is_invuln():
			continue # ignore body
		elif them.parry(self):
			animation_tree[PARAM_PLAYBACK].travel('damage')
			return # interrupt attack
		else:
			hits.append(them)

	for them in hits:
		them.damage(self)


func is_invuln() -> bool:
	return _dash_invuln


func parry(from: Player) -> bool:
	if _parrying:
		print('%s parry attack from %s' % [name, from.name])
		_dash_amount = clamp(_dash_amount + parry_dash, 0.0, 100.0)
		animation_tree[PARAM_PARRY_RECOIL] = true
		return true
	else:
		return false


func damage(from: Player) -> void:
	print('%s took damage from %s' % [name, from.name])
	animation_tree[PARAM_PLAYBACK].travel('damage')
	animation_tree[PARAM_WALK_BLEND] = 0.0
	animation_tree[PARAM_JUMP_ACTIVE] = false


func set_controls_from_input() -> void:
	ctl_move = Input.get_vector('move_left', 'move_right', 'move_down', 'move_up')
	ctl_jump_held = Input.is_action_pressed('move_jump')
	ctl_jump = Input.is_action_just_pressed('move_jump')
	ctl_parry = Input.is_action_just_pressed('combat_parry')
	ctl_stab = Input.is_action_just_pressed('combat_stab')
	ctl_dash = Input.is_action_just_pressed('combat_dash')


func _ready() -> void:
	animation_tree.active = true


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
		elif ctl_dash and _dash_amount >= 100.0:
			_dash_amount = 0.0
			playback_state.travel('dash')
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
