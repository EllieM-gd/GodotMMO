extends Node
class_name Main

const NetworkClient = preload("res://Scripts/websockets_client.gd")
const Packet = preload("res://Scripts/packet.gd")
const Chatbox = preload("res://Scenes/chat_box.tscn")
const ActorPrefab = preload("res://Scenes/actor.tscn")
const mapPrefab = preload("res://Scenes/Map.tscn")
const connectionFailed = preload("res://Scenes/ConnectionFailed.tscn")
const rocksDisplay = preload("res://Scenes/rocks_display.tscn")
const pause_menu = preload("res://Scenes/pause_menu.tscn")

@onready var _login_screen = $Login
@onready var connecting_scene = $Connecting
@onready var _network_client = NetworkClient.new()
var state: Callable
var _chatbox = null
var _rocks = null
var _map = null
var _pause = null
var _username: String
var _player_actor = null
var _actors: Dictionary = {}

func _ready():
	_network_client.connect("connected", self._handle_client_connected)
	_network_client.connect("disconnected", self._handle_client_disconnected)
	_network_client.connect("error", self._handle_network_error)
	_network_client.connect("data", self._handle_network_data)
	Globals.request_rocks.connect(_rock_request)
	add_child(_network_client)
	_network_client.connect_to_server("127.0.0.1", 8081)
	
	#_chatbox.connect("message_sent", self.send_chat)
	_login_screen.connect("login", _handle_login_button)
	_login_screen.connect("register", _handle_register_button)
	_login_screen.connect("character", _send_character_data)
	state = Callable(self, "NONE")
## STATES

func NONE(_p):
	return

func PLAY(_p):
	match _p.action:
		"Chat": # If the packet is a chat message
			var sender: String = _p.payloads[0]
			var message: String = _p.payloads[1] # Grab the message from paylaods
			_chatbox.add_message(sender, message) # Add to our scene
			for act in _actors.values():
				if act.username == sender:
					act.add_text(message)
					break
		"Instance":
			var instance_data: Dictionary = _p.payloads[0]
			var actor = _actors[int(instance_data["id"])]
			if actor != null:
				actor._update_pos(instance_data["x"], instance_data["y"])
		"ModelData":
			var model_data: Dictionary = _p.payloads[0]
			_update_models(model_data)
		"Visual":
			var actor = _actors[int(_p.payloads[2])]
			actor._update_visual(_p.payloads[0],_p.payloads[1])
		"Movement":
			var actor = _actors[int(_p.payloads[2])]
			actor._update_pos(_p.payloads[0],_p.payloads[1])
		"Tp":
			var actor = _actors[int(_p.payloads[2])]
			actor._teleport_player(_p.payloads[0],_p.payloads[1])
		"UpdateRocks":
			if _rocks != null and _actors[int(_p.payloads[0])] == _player_actor:
				_rocks._update(int(_p.payloads[1]))
		"DeleteNode":
			Globals._deleteNode.emit(int(_p.payloads[0]))
		"SpawnNode":
			Globals._spawnNode.emit(int(_p.payloads[0]), float(_p.payloads[1]), float(_p.payloads[2]), float(_p.payloads[3]), int(_p.payloads[4]))
func LOGIN(_p):
	match _p.action:
		"Ok":
			_enter_game()
		"Deny":
			Globals._LoginFailed.emit()
			var reason: String = _p.payloads[0]
			OS.alert(reason)
			state = Callable(self, "NONE")
			
func REGISTER(_p):
	match _p.action:
		"Ok":
			Globals._RegisterConfirmed.emit()
			OS.alert("Registration Complete")
		"Deny":
			Globals._RegisterDenied.emit()
			var reason: String = _p.payloads[0]
			OS.alert(reason)
			state = Callable(self, "NONE")



## FUNCTIONS

func _enter_game():
	state = Callable(self, "PLAY")
	# Remove Login
	remove_child(_login_screen)
	# Add map
	_map = mapPrefab.instantiate()
	add_child(_map)
	# Add Chatbox
	_chatbox = Chatbox.instantiate()
	_chatbox.connect("message_sent", self.send_chat)
	# Add currency (Rocks)
	_rocks = rocksDisplay.instantiate()
	add_child(_rocks)
	add_child(_chatbox)
	
func _update_models(model_data: Dictionary):
	print("Recieved Model Data: " + JSON.stringify(model_data))
	var model_id: int = model_data["id"]
	var func_name: String = "_update_" + model_data["model_type"].to_lower()
	var f: Callable = Callable(self, func_name)
	f.call(model_id, model_data)

func _update_actor(model_id: int, model_data: Dictionary):
	if model_id in _actors:
		_actors[model_id].update(model_data)
	else:
		var new_actor = ActorPrefab.instantiate().init(model_data)
		new_actor.update(model_data)
		if not _player_actor:
			_player_actor = new_actor
			_player_actor.is_player = true  
			_player_actor.MainReference = self
			if _map != null:
				var minimap = _map.find_child("MiniMap").find_child("Control")
				if minimap != null:
					print("Setting up minimap: ", str(minimap))
					minimap.player_node = new_actor.get_child(0)
		_actors[model_id] = new_actor
		add_child(new_actor)
	

func _handle_login_button(username: String, password: String):
	_username = username # Set our username locally
	state = Callable(self, "LOGIN") # Set the state to recieve response packets
	var p: Packet = Packet.new("Login", [username, password]) # Create packet
	_network_client.send_packet(p) # Send packet
	
func _handle_register_button(username: String, password: String):
	state = Callable(self, "REGISTER")
	var p: Packet = Packet.new("Register", [username,password])
	_network_client.send_packet(p)

func _send_character_data(id: int):
	var p: Packet = Packet.new("Character", [id])
	_network_client.send_packet(p)


func send_chat(text: String):
	var p: Packet = Packet.new("Chat", [_username, text])
	_network_client.send_packet(p)
	_chatbox.add_message(_username, text)
	_player_actor.add_text(text)

func _handle_client_connected():
	remove_child(connecting_scene)
	_login_screen.visible = true
	_pause = pause_menu.instantiate()
	add_child(_pause)
	print("Client connected to server!")

func _rock_request(num: int):
	var p = Packet.new("RockRequest", [num])
	_network_client.send_packet(p)

func _handle_client_disconnected(was_clean: bool):
	OS.alert("Disconnected %s" % ["cleanly" if was_clean else "unexpectedly"])
	get_tree().quit()

func _handle_network_data(data: String):
	print("Received server data: ", data)
	var action_payloads: Array = Packet.json_to_action_payloads(data)
	var p: Packet = Packet.new(action_payloads[0], action_payloads[1])
	# Pass the packet to our current state
	state.call(p)

func _delete_node(node_id):
	var p: Packet = Packet.new("DeleteNode", [node_id])
	_network_client.send_packet(p)
	Globals._deleteNode.emit(node_id)
	
func _send_movement_data(actor, x, y):
	if actor == _player_actor:
		var p: Packet = Packet.new("Movement", [x, y])
		_network_client.send_packet(p)

func _send_visual_data(actor, animstate: int, flip: bool):
	if actor == _player_actor:
		var p: Packet = Packet.new("Visual", [animstate, flip])
		_network_client.send_packet(p)

func _handle_network_error():
	print("error signal recieved")
	_login_screen.visible = false
	var scene = connectionFailed.instantiate()
	add_child(scene)

#func _input(event: InputEvent) -> void:
	#if _player_actor and event.is_action_released("click"):
		#var target = _player_actor.body.get_global_mouse_position()
		#_player_actor._player_target = target
		#var p: Packet = Packet.new("Movement", [target.x, target.y])
		#_network_client.send_packet(p)
