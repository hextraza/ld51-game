extends Spatial
class_name Level
func get_class(): return 'Level'


var counter := 0
var elapsed := 0.0
var pingpong := 10.0


signal every_ten_seconds(count)


func reset() -> void:
	counter = 0
	elapsed = 0.0


func _process(delta: float) -> void:
	elapsed += delta
	pingpong = elapsed if counter % 2 == 0 else (10.0 - elapsed)
	if elapsed >= 10.0:
		elapsed -= 10.0
		counter += 1
		emit_signal('every_ten_seconds', counter)
