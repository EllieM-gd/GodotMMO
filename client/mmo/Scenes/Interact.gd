extends Area2D
class_name Interact

var local_player: bool = false

func _ready() -> void:
	body_entered.connect(_body_entered)
	body_exited.connect(_body_left)

func _body_entered(body: Node2D):
	print(body)
	if body.is_in_group("player"):
		body = body.get_parent()
		if body.is_player:
			local_player = true
			body._interact_text(true)

func _body_left(body: Node2D):
	if body.is_in_group("player"):
		body = body.get_parent()
		if body.is_player:
			local_player = false
			body._interact_text(false)

func _interact():
	if Globals.localRecyclingCount > 0:
		# Send rocks request, then reset value
		Globals.request_rocks.emit(Globals.localRecyclingCount * Globals.RecyclingMultiplier)
		Globals.localRecyclingCount = 0
		# TODO: Visual Indicator
		Globals.update_trash.emit(0)
	else:
		print("No Recycling to recycle")

func _input(event: InputEvent) -> void:
	if local_player:
		if event.is_action_pressed("Interact"):
			_interact()
	
