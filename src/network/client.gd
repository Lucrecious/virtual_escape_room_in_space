extends Node

const game_scene := preload('res://src/game/main.tscn')

export(NodePath) var _network_override_path := NodePath()

onready var _network_override := get_node_or_null(_network_override_path) as __Network__
onready var network := _network_override if _network_override else Network

onready var _login := $Login as Screen_Login

var _main: Node

func _ready():
	_main = _login
	
	multiplayer.connect('connected_to_server', self, '_on_connected_to_server')
	multiplayer.connect('server_disconnected', self, '_on_server_disconnected')
	multiplayer.connect('connection_failed', self, '_on_connection_failed')
	
	var success := network.start_connecting_to_server()
	
	_login.connect('create_pressed', self, '_on_create_pressed')
	_login.connect('join_pressed', self, '_on_join_pressed')
	
	network.connect('server_packet_received', self, '_on_server_packet_received')
	
	if success: return
	
	yield(get_tree(), 'idle_frame')
	var dialog := Popups.create_alert(get_viewport())
	dialog.appear('Unable to start connecting to server.', AlertDialog.ERROR_NETWORK)

func _on_server_packet_received(response: String, results: Dictionary) -> void:
	if not results.succeeded:
		var dialog := Popups.create_alert(get_viewport())
		dialog.appear(results.reason, AlertDialog.ERROR_NETWORK)
		return
	
	match response:
		ClientPacket.Response__Room_Created:
			_create_room(results.room_id)
		ClientPacket.Response__Room_ClientID2Usernames:
			if not _main is Game_Main: return
			_main.hud.set_usernames(results.usernames)
		ClientPacket.Response__Room_Joined:
			_create_room(results.room_id)
		ClientPacket.Notification__Room_UserEntered:
			_main.hud.add_username(results.username)

func _create_room(room_id: String) -> void:
	remove_child(_login)
	var game := game_scene.instance() as Game_Main
	_main = game
	add_child(game)
	network.request_from_server(ServerRequest.QueryRoom_ClientID2Usernames, [room_id])

func _on_create_pressed() -> void:
	network.request_from_server(ServerRequest.CreateRoom, [_login.get_username(), _login.get_room_name()])

func _on_join_pressed() -> void:
	network.request_from_server(ServerRequest.JoinRoom, [_login.get_username(), _login.get_room_id()])

func _on_connected_to_server() -> void:
	if _main and _main != _login:
		_main.queue_free()
		_main = null
	
	if _main != _login:
		_main = _login
		add_child(_login)
	
	_login.online()

func _on_server_disconnected() -> void:
	if _main and _main != _login:
		_main.queue_free()
		_main = null
	
	if _main != _login:
		_main = _login
		add_child(_login)
	
	_login.offline()
	_attempt_retry()

func _attempt_retry() -> void:
	yield(get_tree(), 'idle_frame')
	network.stop_connection_to_server()
	yield(get_tree(), 'idle_frame')
	var success := network.start_connecting_to_server()

func _on_connection_failed() -> void:
	_on_server_disconnected()





