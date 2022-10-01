extends Control

onready var timer1 := $Timer1 as Timer
onready var timer2 := $Timer2 as Timer
onready var chime1 := $Chime1 as AudioStreamPlayer
onready var chime2 := $Chime2 as AudioStreamPlayer


func _ready() -> void:
	_on_Timer2_timeout()


func _on_Timer1_timeout() -> void:
	chime2.play()
	timer2.start()


func _on_Timer2_timeout() -> void:
	chime1.play()
	timer1.start()
