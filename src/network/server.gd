extends Node

export(NodePath) var _network_override_path := NodePath()

onready var _log := $Margin/Control/Log as Label
onready var _connect := $Margin/Control/Connect as Button
onready var _disconnect := $Margin/Control/Disconnect as Button

onready var _network_override := get_node_or_null(_network_override_path) as __Network__
onready var network := _network_override if _network_override else Network

# State
onready var _state := $State
var _clients := {}
var _rooms := {}
var _room_count := 0

func _ready() -> void:
	multiplayer.connect('network_peer_connected', self, '_on_client_connected')
	multiplayer.connect('network_peer_disconnected', self, '_on_client_disconnected')
	
	var success := network.start_listening_for_clients()
	if success:
		_disconnect.connect('pressed', self, '_disconnect')
		_connect.connect('pressed', self, '_connect')
		_connect.disabled = true # we already tried to connect
		network.connect('client_request_received', self, '_on_client_request_received')
	else:
		var dialog := Popups.create_alert(get_viewport())
		dialog.appear("Unable to start listening to clients.", AlertDialog.ERROR_NETWORK)

func _on_client_request_received(client_id: int, request: String, args: Array) -> void:
	if request != ServerRequest.UpdateServerClient:
		_log('client request received from %d with request %s' % [client_id, request])
	
	match request:
		ServerRequest.UpdateServerClient:
			_update_server_client(client_id, args[0])
		ServerRequest.CreateRoom:
			var room := _create_room(client_id, args[1])
			if not room:
				network.send_client_packet([client_id], ClientPacket.Response__Room_Created, _create_error_response('error creating room.'))
				return
			
			_join_room(client_id, args[0], room.id)
			return
		ServerRequest.JoinRoom:
			callv('_join_room', [client_id] + args)
			return
		ServerRequest.LeaveRoom:
			var client := _clients.get(client_id, null) as Node
			if not client: return
			
			var success := _leave_room(client)
			if success:
				network.send_client_packet([client_id], ClientPacket.Response__Room_Leave, { succeeded = true })
			else:
				network.send_client_packet([client_id], ClientPacket.Response__Room_Leave, _create_error_response('not in a room.'))

func _update_server_client(client_id: int, data: Dictionary) -> void:
	var client := _clients.get(client_id, null) as Server_Client
	if not client: return
	
	client.position = data.get('position', client.position)
	client.look_at = data.get('look_at', client.look_at)
	client.animation = data.get('animation', '')

func _leave_room(client: Server_Client) -> bool:
	var room := client.get_parent() as Server_Room
	if not room: return false
	
	room.remove_child(client)
	if room.get_clients().size() == 0:
		room.queue_free()
	
	_state.add_child(client)
	
	var room_client_ids := _get_room_client_ids(room.id, [client.id])
	network.send_client_packet(room_client_ids, ClientPacket.Notification__Room_UserLeft, {
		client_id = client.id,
	})
	
	return true

func _get_usernames(ids: PoolIntArray) -> Dictionary:
	var usernames := {}
	
	for id in ids:
		if id == -1: continue
		var client := _clients.get(id, null) as Server_Client
		if not client: continue
		usernames[id] = client.display_name
	
	return usernames
		

func _get_room_client_ids(room_id: String, exceptions := PoolIntArray()) -> PoolIntArray:
	var room := _rooms.get(room_id, null) as Server_Room
	
	if not room:
		return PoolIntArray()
	
	var ids := PoolIntArray()
	for child in room.get_children():
		var client := child as Server_Client
		if not client: continue
		if client.id == -1: continue
		if client.id in exceptions: continue
		ids.push_back(client.id)
	
	return ids

func _join_room(client_id: int, username: String, room_id: String) -> bool:
	var client := _clients.get(client_id, null) as Server_Client
	
	assert(client)
	if not client: return false
	
	if client.get_parent() is Server_Room:
		network.send_client_packet([client_id], ClientPacket.Response__Room_Joined, _create_error_response('client is already in room.'))
		return false
	
	# TODO: Catch more errors
	
	client.display_name = username
	
	var room := _rooms.get(room_id, null) as Server_Room
	if not room:
		network.send_client_packet([client_id], ClientPacket.Response__Room_Joined, _create_error_response('room does not exist.'))
		return false
	
	client.get_parent().remove_child(client)
	room.add_child(client)
	client.position = Vector3(0, 1, 0)
	
	network.send_client_packet([client_id], ClientPacket.Response__Room_Joined, {
		succeeded = true,
		room_id = room_id,
	})
	
	var notify_ids := _get_room_client_ids(room_id)
	for id in notify_ids:
		var client_in_room := _clients.get(id, null) as Server_Client
		if not client_in_room: continue
		
		if client_id == id: continue
		
		network.send_client_packet([client_id], ClientPacket.Notification__Room_UserEntered, {
			client_id = id,
			username = client_in_room.display_name,
			position = client_in_room.position,
			look_at = client_in_room.look_at,
			animation = client_in_room.animation,
		})
	
	network.send_client_packet(notify_ids, ClientPacket.Notification__Room_UserEntered, {
		client_id = client_id,
		username = username,
		position = client.position,
		look_at = client.look_at,
		animation = client.animation,
	})
	
	return true

func _create_room(client_id: int, room_name: String) -> Server_Room:
	var room := Server_Room.new()
	room.display_name = room_name
	
	_room_count += 1
	room.id = str(_room_count)
	
	_rooms[room.id] = room
	
	var sync_clients_timer := Timer.new()
	sync_clients_timer.wait_time = 1.0/20.0
	sync_clients_timer.autostart = true
	sync_clients_timer.one_shot = false
	sync_clients_timer.connect('timeout', self, '_send_clients_sync_data', [room])
	room.add_child(sync_clients_timer)
	
	_state.add_child(room)
	
	return room

func _send_clients_sync_data(room: Server_Room) -> void:
	var clients := room.get_clients()
	var ids := PoolIntArray()
	for c in clients:
		ids.push_back(c.id)
	
	var data := {}
	for c in clients:
		data[c.id] = {
			position = c.position,
			look_at = c.look_at,
			animation = c.animation,
		}
	
	# Sends unreliable
	for id in ids:
		network.send_client_packet([id], ClientPacket.Notification__Room_Sync, data, true)

func _create_error_response(reason: String) -> Dictionary:
	return {
		succeeded = false,
		reason = reason,
	}

func _disconnect() -> void:
	network.stop_listening()
	_connect.disabled = false
	_disconnect.disabled = true
	
	_clear_state()

func _clear_state() -> void:
	for child in _state.get_children():
		child.queue_free()
	
	_clients.clear()
	_rooms.clear()

func _connect() -> void:
	if multiplayer.network_peer.get_connection_status() != NetworkedMultiplayerPeer.CONNECTION_DISCONNECTED: return
	var success := network.start_listening_for_clients()
	_connect.disabled = true
	_disconnect.disabled = false

func _on_client_disconnected(id: int) -> void:
	_log('client disconnectd: %d' % id)
	
	var node := _clients.get(id, null) as Server_Client
	assert(node, 'client can only be disconnected if connected previously')
	if not node: return
	
	_leave_room(node)

	_clients.erase(node)
	node.queue_free()

func _on_client_connected(id: int) -> void:
	_log('client connected: %d' % id)
	
	var client_data := Server_Client.new()
	client_data.id = id
	_state.add_child(client_data)
	_clients[id] = client_data

func _log(text: String) -> void:
	_log.text = (text + '\n\n' + _log.text).left(2000)
