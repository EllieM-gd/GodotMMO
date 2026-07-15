extends CanvasLayer

@onready var b: Button = $VBoxContainer/Button
@onready var r: Button = $VBoxContainer/RESUME

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	visible = false
	b.pressed.connect(_dc)
	r.pressed.connect(_resume)
	

func _dc():
	Globals._player_dc.emit()

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.is_pressed():
		if event.keycode == KEY_ESCAPE:
			visible = not visible

func _resume():
	visible = false
