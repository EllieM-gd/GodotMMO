extends Control

@onready var textDisplay: Label = $CanvasLayer/HBoxContainer/Label

func _update(val: int):
	textDisplay.text = str(val)
