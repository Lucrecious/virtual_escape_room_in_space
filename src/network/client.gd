extends Node

const game_scene := preload('res://src/game/main.tscn')

export(int) var _entity_interpolation_offset_usec := 1_000_000

export(NodePath) var _network_override_path := NodePath()

onready var _network_override := get_node_or_null(_network_override_path) as __Network__
onready var network := _network_override if _network_override else Network

onready var _login := $Login as Screen_Login

var _client_ids_to_usernames := {}
var _client_ids_to_player := {}

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

func _on_server_packet_received(packet: String, results: Dictionary) -> void:
	if 'succeeded' in results:
		if not results.succeeded:
			var dialog := Popups.create_alert(get_viewport())
			dialog.appear(results.reason, AlertDialog.ERROR_NETWORK)
			return
		
		match packet:
			ClientPacket.Response__Room_Joined:
				_create_room(results.room_id)
			ClientPacket.Response__Room_Leave:
				_leave_room()
				return
	else:
		var game := _main as Game_Main
		match packet:
			ClientPacket.Notification__Room_UserEntered:
				if not game: return
				game.hud.add_username(results.username)
				var player: PlayerDummy
				if results.client_id == multiplayer.get_network_unique_id():
					player = game.level.add_player_local()
				else:
					player = game.level.add_player_dummy()
				
				player.global_transform.origin = results.position
				_client_ids_to_player[results.client_id] = player
				
			ClientPacket.Notification__Room_UserLeft:
				_main.hud.clear_usernames()
				_client_ids_to_usernames.erase(results.client_id) 
				_main.hud.set_usernames(_client_ids_to_usernames.values())
				
				var player := _client_ids_to_player.get(results.client_id, null) as PlayerDummy
				if not player: return
				_client_ids_to_player.erase(player)
				player.queue_free()
			
			ClientPacket.Notification__Room_Sync:
				var sync_data := {
					data = results.duplicate(),
					usec_received = OS.get_ticks_usec()
				}
				_player_history_data.enqueue(sync_data)
				
func _leave_room() -> void:
	if _main is Game_Main:
		_main.queue_free()
		_main = null
	
	if _main != _login:
		_main = _login
		add_child(_login)

func _create_room(room_id: String) -> void:
	remove_child(_login)
	var game := game_scene.instance() as Game_Main
	_main = game
	add_child(game)
	
	var client_update_timer := Timer.new()
	client_update_timer.wait_time = 1.0/20.0
	client_update_timer.autostart = true
	client_update_timer.one_shot = false
	client_update_timer.connect('timeout', self, '_send_server_local_update')
	game.add_child(client_update_timer)
	
	game.hud.leave_button.connect('pressed', self, '_on_gui_leave_room_requested')

func _send_server_local_update() -> void:
	var player := _client_ids_to_player.get(multiplayer.get_network_unique_id(), null) as PlayerDummy
	if not player: return
	
	network.request_from_server(ServerRequest.UpdateServerClient, [{
		position = player.global_transform.origin,
		look_at = -player.global_transform.basis.z,
		animation = player.animation_player.current_animation(),
	}])

func _on_gui_leave_room_requested() -> void:
	network.request_from_server(ServerRequest.LeaveRoom)

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

var _player_history_data := RingBuffer.new(1000)

# Interpolation
func _physics_process(delta: float) -> void:
	var interpolation_usec := OS.get_ticks_usec() - _entity_interpolation_offset_usec
	
	var count := _player_history_data.size()
	for i in range(1, count):
		var lower_data := _player_history_data.at(count - i - 1) as Dictionary
		var lower_usec := lower_data.usec_received as int
		if interpolation_usec < lower_usec: continue
		
		# Interpolate...
		
		var upper_data := _player_history_data.at(count - i) as Dictionary
		var upper_usec := upper_data.usec_received as int
		
		var ratio := float(interpolation_usec - lower_usec) / float(upper_usec - lower_usec)
		
		for id in upper_data.data:
			if id == multiplayer.get_network_unique_id(): continue
			var player := _client_ids_to_player.get(id, null) as PlayerDummy
			if not player: continue
			
			if not id in lower_data.data:
				player.global_transform.origin = upper_data.data[id].position
				continue
			
			var lower_position := lower_data.data[id].position as Vector3
			var upper_position := upper_data.data[id].position as Vector3
			var interpolated_position := lerp(lower_position, upper_position, ratio) as Vector3
			player.global_transform.origin = interpolated_position
			
			var lower_look_at := lower_data.data[id].look_at as Vector3
			var upper_look_at := upper_data.data[id].look_at as Vector3
			var interpolated_look_at := lerp(lower_look_at, upper_look_at, ratio) as Vector3
			player.look_at(player.global_transform.origin + interpolated_look_at, Vector3.UP)
			
			var animation := lower_data.data[id].animation as String
			if not animation.empty() and player.animation_player.current_animation() != lower_data.data[id].animation:
				player.animation_player.play(lower_data.data[id].animation)
		break



