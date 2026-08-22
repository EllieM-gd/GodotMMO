extends Node

const Packet = preload("res://Scripts/packet.gd")

signal connected
signal data(data_string)
signal disconnected(was_clean)
signal error

var _client = WebSocketPeer.new()
var _last_state = WebSocketPeer.STATE_CLOSED
var client_tls_options

func _ready() -> void:
	#var client_trusted_cas = load("res://Scripts/SpecialKey/server.crt")
	#client_tls_options = TLSOptions.client(client_trusted_cas, "localhost")
	Globals._player_dc.connect(player_disconnect)


func connect_to_server(hostname: String, port: int) -> void:
	var websocket_url = "wss://%s:%d" % [hostname, port]
	var err = _client.connect_to_url(websocket_url, TLSOptions.client())
	if err != OK:
		print("Unable to initiate connection")
		error.emit()
		set_process(false)
	else:
		_last_state = WebSocketPeer.STATE_CONNECTING
		set_process(true)

func send_packet(packet: Packet) -> void:
	_send_string(packet.tostring())

func _process(_delta):
	_client.poll()
	var state = _client.get_ready_state()
	# 1. Handle State Transitions
	if state != _last_state:
		if state == WebSocketPeer.STATE_OPEN:
			print("Connected to server")
			connected.emit()
		elif state == WebSocketPeer.STATE_CLOSED:
			var code = _client.get_close_code()
			var reason = _client.get_close_reason()
			print("Closed, code: %d, reason: %s" % [code, reason])
			disconnected.emit(code != -1) # true if closed cleanly, false if abrupt
			set_process(false)
		_last_state = state

	# 2. Handle Incoming Data (If Open)
	if state == WebSocketPeer.STATE_OPEN:
		while _client.get_available_packet_count() > 0:
			_on_data()

func _on_data():
	var packet_bytes = _client.get_packet()
	var data_string: String = packet_bytes.get_string_from_utf8()
	data.emit(data_string)

func _send_string(string: String) -> void:
	_client.put_packet(string.to_utf8_buffer())
	if not "Movement" in string and not "Visual" in string: 
		print("Sent string: ", string)

func player_disconnect():
	_client.close(1000, "Player Disconnected")
