extends KinematicBody

export(float, 1, 9) var move_speed := TAU
export(float, 1, 20) var move_scale := 12.0
export(float, 1, 20) var stop_scale := 15.0
export(float, 1, 3) var jump_height := 1.2
export(float, 1, 10) var jump_scale := PI
export(float, 1, 10) var fall_scale := PI * 3/2
export(float, 0, 20) var camera_scale := PI
export(NodePath) var camera_path : NodePath

onready var camera : Camera = get_node_or_null(camera_path)

var gravity : float = ProjectSettings.get_setting('physics/3d/default_gravity')
var velocity := Vector3.ZERO


func _ready() -> void:
	if not camera:
		set_process(false)
		push_error('Player camera missing')


func _process(delta: float) -> void:
	var target := Vector3(translation.x, translation.y + 1.5, camera.translation.z)
	camera.translation = camera.translation.linear_interpolate(target, camera_scale * delta)


func _physics_process(delta):
	var input_move := Input.get_vector('move_left', 'move_right', 'ui_down', 'ui_up')
	var input_jump := Input.is_action_pressed('move_jump')
	var input_jump_now := Input.is_action_just_pressed('move_jump')

	if is_zero_approx(input_move.x):
		velocity.x = lerp(velocity.x, 0.0, stop_scale * delta)
	else:
		velocity.x = lerp(velocity.x, input_move.x * move_speed, move_scale * delta)

	var snap := Vector3.ZERO if input_jump else Vector3.DOWN

	if input_jump_now and is_on_floor():
		velocity.y += sqrt(2 * jump_height * gravity * jump_scale)
	elif input_jump and velocity.y > 0.0:
		velocity.y -= gravity * jump_scale * delta
	else:
		velocity.y -= gravity * fall_scale * delta

	velocity = move_and_slide_with_snap(velocity, snap, Vector3.UP)
