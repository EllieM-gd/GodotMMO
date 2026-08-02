extends "res://Scripts/model.gd"
class_name Actor

@onready var body: CharacterBody2D = $CharacterBody2D
@onready var label: Label = $CharacterBody2D/Label
@onready var sprite: AnimatedSprite2D = $CharacterBody2D/Sprite2D
@onready var _camera: Camera2D = $CharacterBody2D/Camera2D
@onready var chatContainer: VBoxContainer = $CharacterBody2D/ChatContainer
@onready var interact_text: Label = $CharacterBody2D/InteractText

var chat = preload("res://Scenes/Chat.tscn")

var animations = {
	0: "Idle",
	1: "Run"
}
var animationState: int = 0
var avatar_id: int = 4

var server_position: Vector2
var actor_name: String
var velocity: Vector2 = Vector2.ZERO

var MainReference: Main = null

var is_player: bool = false
var lastPositionSent = Vector2(0,0)
var lastVisualSent: int = animationState
var username: String = ""

var canSend: bool = true
var sendDelay: float = 0

@export var speed: float = 100
var inputEnabled: bool = true

var _network_target_position: Vector2 = Vector2.ZERO
var _has_received_position: bool = false

func update(new_model: Dictionary):
	var ientity = new_model["instanced_entity"]
	var mactor = new_model["user"]
	if mactor != null:
		print(mactor)
	server_position = Vector2(float(ientity["x"]),float(ientity["y"]))
	actor_name = ientity["entity"]["name"]
	if new_model.has("avatar_id"):
		avatar_id = int(new_model["avatar_id"])
		if sprite != null:
			sprite.sprite_frames = Globals.Characters[avatar_id]
	else:
		printerr("No Avatar ID Found")
	if label:
		label.text = actor_name

func init(model_data: Dictionary) -> Actor:
	# Navigate the dictionary to get the name
	username = model_data["instanced_entity"]["entity"]["name"]
	return self
func _ready():
	# Ensure the UI updates when the node enters the tree
	label.text = username
	body.global_position.x = server_position.x
	body.global_position.y = server_position.y
	interact_text.visible = false
	
	sprite.sprite_frames = Globals.Characters[avatar_id]
	# Enable camera if local player
	if is_player:
		sprite.z_index = 5 # Ensure Local player is always on top
		_camera.enabled = true
		Globals.localPlayerUsername = username
		Globals.chatTyping.connect(toggleInput)
func toggleInput(val: bool):
	inputEnabled = not val
func add_text(s: String):
	var c = chat.instantiate()
	c._set_text(s)
	chatContainer.add_child(c)
	chatContainer.move_child(c, 0)
	if chatContainer.get_child_count() > 3:
		chatContainer.get_child(3).queue_free()

func _update_pos(x: float, y: float):
	# If it's your own local player, don't let incoming server data snap you backwards
	if is_player:
		return
		
	# Update our target instantly to the absolute newest packet data
	_network_target_position = Vector2(x, y)
	
	# If this is the first packet ever, snap instantly so they don't slide from (0,0)
	if not _has_received_position:
		body.global_position = _network_target_position
		_has_received_position = true
func _teleport_player(x: float, y: float):
	# Update our target instantly to the absolute newest packet data
	_network_target_position = Vector2(x, y)
	body.global_position = _network_target_position
	_has_received_position = true

func _update_visual(state: int, flip: bool):
	animationState = state
	sprite.flip_h = flip


func _physics_process(delta: float) -> void:
	if not body or not inputEnabled:
		return
	sprite.play(animations[animationState])
	if is_player:
		var x_direction = Input.get_axis("left","right")
		var y_direction = Input.get_axis("up", "down")
		body.velocity.x = x_direction * speed
		body.velocity.y = y_direction * speed
		#if x_direction == 0:
			#body.velocity.x = move_toward(body.velocity.x, 0, delta * speed)
		#if y_direction == 0:
			#body.velocity.y = move_toward(body.velocity.y, 0, delta * speed)
		body.move_and_slide()
		
		if lastPositionSent != Vector2(body.global_position.x, body.global_position.y):
			# Set state to walking
			animationState = 1
			if body.global_position.x != lastPositionSent.x:
				# If we moved on the X axis orient ourselves
				sprite.flip_h = body.global_position.x > lastPositionSent.x
			if MainReference != null and canSend:
				MainReference._send_movement_data(self,body.global_position.x,body.global_position.y)
				MainReference._send_visual_data(self, animationState, sprite.flip_h)
				lastVisualSent = animationState
				lastPositionSent = Vector2(body.global_position.x, body.global_position.y)
				canSend = false
		else: # we are not moving, so go to idle state
			animationState = 0 
			if lastVisualSent != 0:
				MainReference._send_visual_data(self, animationState, sprite.flip_h)
				lastVisualSent = animationState
		if canSend == false:
			sendDelay += delta * 60
			if sendDelay >= 3: # 3 Frames in between sends
				sendDelay = 0
				canSend = true
	else:
		if _has_received_position:
			# If they are incredibly far away (e.g., teleported across the map), just snap them
			if body.global_position.distance_to(_network_target_position) > 100.0:
				body.global_position = _network_target_position
			else:
				# Slide towards the newest position aggressively
				# A weight of 25.0 or higher makes it snap incredibly fast while keeping a pixel-blend
				body.global_position = body.global_position.lerp(_network_target_position, 25.0 * delta)
			
func _interact_text(status: bool) -> void:
	interact_text.visible = status
