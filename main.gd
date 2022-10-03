extends Node

var stab_delay := 0.0

func _physics_process(delta: float) -> void:
	stab_delay -= delta
	var stabby := stab_delay < 0.0
	if stabby: stab_delay = rand_range(1.0, 5.0)
	$World/Dummy.ctl_move = Vector2(-0.05, 0)
	$World/Dummy.ctl_stab = stabby
