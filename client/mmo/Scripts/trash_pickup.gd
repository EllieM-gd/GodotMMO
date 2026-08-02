extends "res://Scenes/Interact.gd"
var id: int = -1

func _interact():
	# Update locally
	Globals.localRecyclingCount += 1
	# Cap the number to our max
	Globals.localRecyclingCount = min(Globals.localRecyclingCount, Globals.localMaxRecyclingCount)
	get_tree().current_scene._delete_node(id)
