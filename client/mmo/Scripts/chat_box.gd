extends Control

@onready var chat_log = $CanvasLayer/VBoxContainer/RichTextLabel
@onready var input_field = $CanvasLayer/VBoxContainer/HBoxContainer/LineEdit
@onready var hbox = $CanvasLayer/VBoxContainer/HBoxContainer
signal message_sent(message)


func _toggleVisible():
	hbox.visible = not hbox.visible
	chat_log.visible = not chat_log.visible
	
func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.is_pressed():
		match event.keycode:
			Key.KEY_ESCAPE:
				input_field.release_focus()
			Key.KEY_ENTER:
				input_field.grab_focus()
	
func text_entered(text: String):
	if len(text) > 0:
		input_field.text = ""
		
		message_sent.emit(text)

func add_message(username: String, text: String):
	chat_log.text += "[" + username + "] " + text + "\n"


func _on_line_edit_editing_toggled(toggled_on: bool) -> void:
	Globals.chatTyping.emit(toggled_on)
