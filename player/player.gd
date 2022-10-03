extends KinematicBody
class_name Player
func get_class(): return 'Player'


export var use_input := false
export var dash_from_parry := 25.0

const PARAM_PLAYBACK = 'parameters/playback'
const PARAM_WALK_BLEND = 'parameters/move/walk/blend_position'
const PARAM_JUMP_ACTIVE = 'parameters/move/jump/active'
const PARAM_PARRY_RECOIL = 'parameters/parry/recoil/active'

onready var animation_tree := $AnimationTree as AnimationTree
onready var area_reach := $'%AreaReach' as Area

var ctl_move := Vector2.ZERO
var ctl_jump := false
var ctl_parry := false
var ctl_stab := false
var ctl_dash := false

var velocity := Vector3.ZERO
var parrying := false
var dash_amount := 0.0
var turbofish := false


func stab() -> void:
	for body in area_reach.get_overlapping_bodies():
		print(body)
		if body != self:
			if not body.stabbed(self):
				animation_tree[PARAM_PLAYBACK].travel('damage')
			return


func attacked(from: CollisionObject) -> bool:
	if parrying and is_forward(from):
		print('parry')
		dash_amount = clamp(dash_amount + dash_from_parry, 0.0, 100.0)
		animation_tree[PARAM_PARRY_RECOIL] = true
		return false
	else:
		print('attacked')
		animation_tree[PARAM_PLAYBACK].travel('damage')
		animation_tree[PARAM_WALK_BLEND] = 0.0
		animation_tree[PARAM_JUMP_ACTIVE] = false
		return true


func is_forward(node: Spatial) -> bool:
	var dir := node.global_translation - global_translation
	return global_transform.basis.z.dot(dir) > 0.0


func set_controls_from_input() -> void:
	ctl_move = Input.get_vector('move_left', 'move_right', 'move_down', 'move_up')
	ctl_jump = Input.is_action_just_pressed('move_jump')
	ctl_parry = Input.is_action_just_pressed('combat_parry')
	ctl_stab = Input.is_action_just_pressed('combat_stab')
	ctl_dash = Input.is_action_just_pressed('combat_dash')


func _on_every_ten_seconds(count:int) -> void:
	turbofish = count % 2 == 1


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
		animation_tree[PARAM_WALK_BLEND] = walk_blend

	if can_attack:
		if ctl_jump:
			animation_tree[PARAM_JUMP_ACTIVE] = true
		elif ctl_parry:
			playback_state.travel('parry')
			animation_tree[PARAM_PARRY_RECOIL] = false
		elif ctl_stab:
			playback_state.travel('stab')
		elif ctl_dash and dash_amount >= 100.0:
			dash_amount = 0.0
			playback_state.travel('dash')

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
