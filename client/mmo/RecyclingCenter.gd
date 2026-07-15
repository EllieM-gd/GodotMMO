extends Node2D

@onready var cow: Sprite2D = $NPC

var local_player_entered: bool = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if local_player_entered:
		if Input.is_action_just_pressed("Interact"):
			_toggle_shop()


func _on_timer_timeout() -> void:
	cow.frame = 1 if cow.frame == 0 else 0


func _body_entered(body: Node2D) -> void:
	var p = body.get_parent()
	if p.is_player:
		local_player_entered = true

func _body_exited(body: Node2D) -> void:
	var p = body.get_parent()
	if p.is_player:
		local_player_entered = false

func _toggle_shop():
	pass
