extends Node


onready var player := $'World/Player' as Player
onready var dummy := $'World/Dummy' as Player
onready var ui_dash_bar := $'UI/DashBar' as ProgressBar


var stab_delay := 0.0


func _process(_delta: float) -> void:
	ui_dash_bar.value = player._dash_amount


func _physics_process(delta: float) -> void:
	stab_delay -= delta
	var stabby := stab_delay < 0.0
	if stabby: stab_delay = rand_range(1.0, 5.0)
	dummy.ctl_move = Vector2(-0.05, 0)
	dummy.ctl_stab = stabby
