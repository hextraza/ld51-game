extends Spatial

export(float, EXP, 0.1, 10.0) var interpolation_rate := TAU

export(NodePath) onready var default_target : NodePath

onready var target := get_node(default_target) as Spatial

func _physics_process(delta: float) -> void:
	global_translation = lerp(global_translation, target.global_translation, delta * interpolation_rate)
