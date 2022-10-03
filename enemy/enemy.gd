extends KinematicBody
class_name Enemy
func get_class(): return 'Enemy'


const PARAM_PLAYBACK = 'parameters/playback'
const PARAM_WALK_BLEND = 'parameters/move/blend_position'

export var attack1 : AudioStream
export var attack2 : AudioStream
export var attack3 : AudioStream
export var attack4 : AudioStream
export var death1 : AudioStream
export var death2 : AudioStream
export var death3 : AudioStream
export var death4 : AudioStream

onready var animation_tree := $AnimationTree as AnimationTree
onready var area_reach := $AreaReach as Area
onready var sound_attack := $Armature/Skeleton/Head/SoundAttack as AudioStreamPlayer3D
onready var sound_death := $Armature/Skeleton/Head/SoundDeath as AudioStreamPlayer3D


var velocity := Vector3.ZERO


func cue_attack() -> void:
	print(self)
	match randi() % 4:
		0: sound_attack.stream = attack1
		1: sound_attack.stream = attack2
		2: sound_attack.stream = attack3
		3: sound_attack.stream = attack4
	sound_attack.play()


func cue_death() -> void:
	print(self)
	match randi() % 4:
		0: sound_death.stream = death1
		1: sound_death.stream = death2
		2: sound_death.stream = death3
		3: sound_death.stream = death4
	sound_death.play()


func do_attack() -> void:
	print(self)
	for body in area_reach.get_overlapping_bodies():
		print(body)
		if body != self:
			if not body.attacked(self):
				animation_tree[PARAM_PLAYBACK].travel('attack-failed')
			return


func stabbed(from: CollisionObject) -> bool:
	if from.turbofish or not is_forward(from):
		print('stabbed')
		animation_tree[PARAM_PLAYBACK].travel('death')
		cue_death()
		set_collision_layer_bit(2, false)
		set_collision_mask_bit(2, false)
		return true
	else:
		print('block stab')
		animation_tree[PARAM_PLAYBACK].travel('block')
		return false


func is_forward(node: Spatial) -> bool:
	var dir := node.global_translation - global_translation
	return global_transform.basis.z.dot(dir) < 0.0


func _physics_process(delta:float) -> void:
	var	aggro := get_tree().get_nodes_in_group('player').front() as Player

	var playback_state := animation_tree[PARAM_PLAYBACK] as AnimationNodeStateMachinePlayback

	var can_attack := is_on_floor() \
		and playback_state.get_current_node() == 'move' \
		and playback_state.get_travel_path().empty()

	var urge_attack := area_reach.overlaps_body(aggro)
	if urge_attack:
		animation_tree[PARAM_WALK_BLEND] = 0.0
	else:
		var dir := aggro.global_translation - global_translation
		animation_tree[PARAM_WALK_BLEND] = dir.x

	if can_attack:
		if randf() > 0.5 and urge_attack:
			playback_state.travel('attack')
		elif not is_forward(aggro):
			playback_state.travel('turn')

	var	root_motion := animation_tree.get_root_motion_transform()
	var linear_motion := transform.basis * root_motion.origin / delta

	# Angular motion
	transform.basis *= root_motion.basis

	# Linear motion
	if is_on_floor():
		velocity = linear_motion
	else:
		velocity.x = linear_motion.x
		velocity.y -= 10.0 * delta
	velocity = move_and_slide(velocity, Vector3.UP)

	# Rails, just to be sure
	translation.z = 0.0
	velocity.z = 0.0
