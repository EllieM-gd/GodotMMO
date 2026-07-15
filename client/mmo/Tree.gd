extends Node2D

@onready var respawnTimer = $Timer
@onready var sprite = $Sprite2D

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


func _on_area_2d_body_entered(body: Node2D) -> void:
	if body.get_parent().is_player:
		sprite.modulate = Color(1.0, 1.0, 1.0, 0.263)
	



func _on_area_2d_body_exited(body: Node2D) -> void:
	if body.get_parent().is_player:
		sprite.modulate = Color(1.0, 1.0, 1.0, 1.0)


func _on_timer_timeout() -> void:
	pass # Replace with function body.
