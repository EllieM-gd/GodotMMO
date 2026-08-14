extends CanvasLayer

func _ready():
	visible = false 
	Globals.openShop.connect(func(): visible = true)
	Globals.closeShop.connect(func(): visible = false)


func _on_button_pressed() -> void:
	Globals.closeShop.emit()
