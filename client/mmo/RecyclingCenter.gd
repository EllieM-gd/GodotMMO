extends Node2D

@onready var cow: Sprite2D = $NPC

func _on_timer_timeout() -> void:
	cow.frame = 1 if cow.frame == 0 else 0
