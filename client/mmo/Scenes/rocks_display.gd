extends Control

@onready var textDisplay: Label = $CanvasLayer/Rocks/Label
@onready var trashDisplay = $CanvasLayer/Trash
@onready var trashLabel: Label = $CanvasLayer/Trash/Label

func _update(val: int):
	textDisplay.text = str(val)
	Globals.rock_count = val


func _ready() -> void:
	Globals.update_trash.connect(trash_count_updated)
	trashDisplay.visible = false
	

func trash_count_updated(c: int):
	if c == 0:
		trashDisplay.visible = false
	else:
		trashDisplay.visible = true
		trashLabel.text = str(c) + "/" + str(Globals.localMaxRecyclingCount)
