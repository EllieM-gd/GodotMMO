extends "res://Scenes/Interact.gd"
var id: int = -1

func _interact():
	if Globals.localRecyclingCount >= Globals.localMaxRecyclingCount:
		# TODO: Maybe tell player they cant pick up somehow
		return
	# Update locally
	Globals.localRecyclingCount += 1
	# Cap the number to our max
	Globals.localRecyclingCount = min(Globals.localRecyclingCount, Globals.localMaxRecyclingCount)
	Globals.update_trash.emit(Globals.localRecyclingCount)
	get_tree().current_scene._delete_node(id)
