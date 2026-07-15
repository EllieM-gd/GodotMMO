extends Control

# Login References
@onready var username_field: LineEdit = $CanvasLayer/VBoxContainer/GridContainer/LineEdit_Username
@onready var password_field: LineEdit = $CanvasLayer/VBoxContainer/GridContainer/LineEdit_Password
@onready var login_button: Button = $CanvasLayer/VBoxContainer/CenterContainer/HBoxContainer/Button_Login
@onready var register_button: Button = $CanvasLayer/VBoxContainer/CenterContainer/HBoxContainer/Button_Register
@onready var registration_response: Label = $CanvasLayer/VBoxContainer/RegistrationResponse

# Character References
@onready var panel: Panel = $CanvasLayer/Panel
@onready var character_sprite: AnimatedSprite2D = $CanvasLayer/Panel/Control/AnimatedSprite2D
@onready var left: Button = $CanvasLayer/Panel/VBoxContainer/HBoxContainer/Left
@onready var right: Button = $CanvasLayer/Panel/VBoxContainer/HBoxContainer/Right
@onready var okay: Button = $CanvasLayer/Panel/VBoxContainer/HBoxContainer/Okay

@onready var canvaslayer = $CanvasLayer

var avatar_ID: int = 4

signal login(username, password)
signal register(username, password)
signal character(id)

func _process(delta: float) -> void:
	canvaslayer.visible = visible
	

func _ready() -> void:
	panel.visible = false
	registration_response.visible = true
	registration_response.text = ""
	password_field.secret = true
	character_sprite.sprite_frames = Globals.Characters[avatar_ID]
	character_sprite.play("Idle")
	# Main Buttons
	login_button.connect("pressed", _login)
	register_button.connect("pressed", _register)
	# Global Server Events
	Globals._RegisterConfirmed.connect(_register_confirmed)
	Globals._RegisterDenied.connect(_register_denied)
	Globals._LoginFailed.connect(_loginFailed)
	Globals._LoginSuccess.connect(_loginSuccess)
	# Character Buttons
	okay.pressed.connect(_Character_selected)
	left.pressed.connect(_left)
	right.pressed.connect(_right)
	check_auto_login()
	
func _login():
	login_button.disabled = true
	register_button.disabled = true
	login.emit(username_field.text, password_field.text)
	registration_response.text = "Logging in..."
func _loginFailed():
	register_button.disabled = false
	login_button.disabled = false
	registration_response.text = "Login Failed."
func _loginSuccess():
	registration_response.text = "Joining Game!"

func _register():
	login_button.disabled = true
	register_button.disabled = true
	registration_response.text = "Waiting for server..."
	register.emit(username_field.text, password_field.text)
func _register_confirmed():
	panel.visible = true
	registration_response.text = "REGISTRATION SUCCESSFUL\nPLEASE SELECT CHARACTER"
func _register_denied():
	login_button.disabled = false
	register_button.disabled = false
	registration_response.text = "REGISTRATION FAILED :("


func _Character_selected():
	login_button.disabled = false
	character.emit(avatar_ID)
	panel.visible = false
	registration_response.text = "Character set!"
func _left():
	if avatar_ID - 1 < 0:
		avatar_ID = len(Globals.Characters) - 1
	else:
		avatar_ID -= 1
	character_sprite.sprite_frames = Globals.Characters[avatar_ID]
	character_sprite.play("Idle")
func _right():
	if avatar_ID + 1 > len(Globals.Characters) - 1:
		avatar_ID = 0
	else:
		avatar_ID += 1
	character_sprite.sprite_frames = Globals.Characters[avatar_ID]
	character_sprite.play("Idle")
	
# Call this in your login screen's _ready() function
func check_auto_login() -> void:
	var args: PackedStringArray = OS.get_cmdline_args()
	
	# Loop through the arguments to find custom flags
	for i in range(args.size()):
		if args[i] == "--username" and i + 1 < args.size():
			username_field.text = args[i + 1]
		elif args[i] == "--password" and i + 1 < args.size():
			password_field.text = args[i + 1]
