extends Node

var _main: Node

func _ready():
	_main = $Login
	
	multiplayer.connect('connected_to_server', self, '_on_connected_to_server')
	multiplayer.connect('server_disconnected', self, '_on_server_disconnected')
	multiplayer.connect('connection_failed', self, '_on_connection_failed')
	
	var success := Network.start_connecting_to_server(self)
	
	var login := $Login as Screen_Login
	login.connect('create_pressed', self, '_on_create_pressed', [login])
	login.connect('join_pressed', self, '_on_join_pressed', [login])
	
	if success: return
	
	yield(get_tree(), 'idle_frame')
	var dialog := Popups.create_alert(get_viewport())
	dialog.appear('Unable to start connecting to server.', AlertDialog.ERROR_NETWORK)

func _on_create_pressed(login: Screen_Login) -> void:
	Network.request_create_room(login.get_username(), login.get_room_name(), self, '_on_room_created')

func _on_room_created() -> void:
	print('room created!')

func _on_join_pressed() -> void:
	pass

func _on_connected_to_server() -> void:
	if not _main: return
	if not _main.has_method('online'): return
	_main.online()

func _on_server_disconnected() -> void:
	if not _main: return
	if not _main.has_method('offline'): return
	_main.offline()
	
	_attempt_retry()

func _attempt_retry() -> void:
	yield(get_tree(), 'idle_frame')
	Network.stop_connection_to_server(self)
	yield(get_tree(), 'idle_frame')
	var success := Network.start_connecting_to_server(self)

func _on_connection_failed() -> void:
	_on_server_disconnected()





