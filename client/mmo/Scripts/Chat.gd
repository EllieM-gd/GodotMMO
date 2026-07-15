extends Button

func _set_text(s: String):
	text = s


func _on_timer_timeout() -> void:
	while modulate.a > 0:
		modulate.a -= 0.02
		await get_tree().create_timer(0.01).timeout
	queue_free()
