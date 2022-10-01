extends KinematicBody

export(float, 1, 9) var speed := 5.0
export(float, 1, 9) var jump_height := 1.5
export(float, 1, 9) var fall_faster := 2.0

export(NodePath) var camera : NodePath

onready var _camera : Camera = get_node_or_null(camera)

var gravity : float = ProjectSettings.get_setting('physics/3d/default_gravity')

var velocity := Vector3.ZERO


func _ready() -> void:
	if not _camera:
		set_process(false)
		push_error('Player camera missing')


func _process(delta: float) -> void:
	var target := Vector3(translation.x, translation.y + 1.5, _camera.translation.z)
	_camera.translation = _camera.translation.linear_interpolate(target, delta * PI)


func _physics_process(delta):
	var input_move := Input.get_vector('move_left', 'move_right', 'ui_down', 'ui_up')
	var input_jump := Input.is_action_just_pressed('move_jump')
	var snap := Vector3.ZERO if input_jump else Vector3.DOWN

	velocity.x = input_move.x * speed

	if input_jump and is_on_floor():
		velocity.y += sqrt(2 * jump_height * gravity)
	else:
		velocity.y -= gravity * (fall_faster if velocity.y < 0.0 else 1.0) * delta

	velocity = move_and_slide_with_snap(velocity, snap, Vector3.UP, true)
