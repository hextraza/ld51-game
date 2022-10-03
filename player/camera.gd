extends Spatial

export(float, EXP, 0.1, 10.0) var interpolation_rate := TAU

export(NodePath) var default_level : NodePath
export(NodePath) var default_player : NodePath

onready var level := get_node(default_level) as Level
onready var player := get_node(default_player) as Player
onready var ui_dash_bar := $UI/HUD/DashBar as ProgressBar
onready var ui_time_label := $UI/HUD/Time/Label as Label


func _process(_delta: float) -> void:
	ui_dash_bar.value = player.dash_amount
	ui_time_label.text = '%d' % [10.0 - level.elapsed]
	if player.turbofish:
		ui_time_label.modulate = Color.from_hsv(level.elapsed, 0.5, 1, 1)
	else:
		ui_time_label.modulate = Color.white


func _physics_process(delta: float) -> void:
	global_translation = lerp(global_translation, player.global_translation, delta * interpolation_rate)
