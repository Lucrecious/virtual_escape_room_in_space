extends Node

export(NodePath) var _network_override_path := NodePath()

onready var _log := $Margin/Control/Log as Label
onready var _connect := $Margin/Control/Connect as Button
onready var _disconnect := $Margin/Control/Disconnect as Button

onready var _network_override := get_node_or_null(_network_override_path) as __Network__
onready var network := _network_override if _network_override else Network

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
	_log('client request received from %d with request %s' % [client_id, request])
	match request:
		ServerRequest.CreateRoom:
			callv('_create_room', [client_id] + args)
			return
		ServerRequest.JoinRoom:
			callv('_join_room', [client_id] + args)
			return
		ServerRequest.QueryRoom_ClientID2Usernames:
			var room_id := args[0] as String
			var room_client_ids := _get_room_client_ids(room_id)
			var usernames := _get_usernames(room_client_ids)
			
			network.send_client_packet([client_id], ClientPacket.Response__Room_ClientID2Usernames, {
				succeeded = true,
				client_ids = room_client_ids,
				usernames = usernames,
			})
			_log('sending client id to username mapping to %d for room %s: %s' % [client_id, room_id, str(usernames)] )
			return

func _get_usernames(ids: PoolIntArray) -> PoolStringArray:
	var usernames := PoolStringArray()
	
	for id in ids:
		if id == -1: continue
		var client := _clients.get(id, null) as Server_Client
		if not client: continue
		usernames.push_back(client.display_name)
	
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

func _join_room(client_id: int, username: String, room_id: String) -> void:
	var client := _clients.get(client_id, null) as Server_Client
	
	assert(client)
	if not client: return
	
	if client.get_parent() is Server_Room:
		network.send_client_packet([client_id], ClientPacket.Response__Room_Joined, _create_error_response('client is already in room.'))
		return
	
	# TODO: Catch more errors
	
	client.display_name = username
	
	var room := _rooms.get(room_id, null) as Server_Room
	if not room:
		network.send_client_packet([client_id], ClientPacket.Response__Room_Joined, _create_error_response('room does not exist.'))
		return
	
	client.get_parent().remove_child(client)
	room.add_child(client)
	
	network.send_client_packet([client_id], ClientPacket.Response__Room_Joined, {
		succeeded = true,
		room_id = room_id,
	})
	
	var notify_ids := PoolIntArray()
	for id in _get_room_client_ids(room_id, [client_id]):
		notify_ids.push_back(id)
	
	network.send_client_packet(notify_ids, ClientPacket.Notification__Room_UserEntered, {
		client_id = client_id,
		username = username,
	})

func _create_room(client_id: int, username: String, room_name: String) -> void:
	var client := _clients.get(client_id, null) as Server_Client
	
	assert(client)
	if not client: return
	
	if client.get_parent() is Server_Room:
		network.send_client_packet([client_id], ClientPacket.Response__Room_Joined, _create_error_response('client is already in room.'))
		return
	
	# TOOD: Catch more errors
	
	client.display_name = username
	
	var room := Server_Room.new()
	room.display_name = room_name
	
	_room_count += 1
	room.id = str(_room_count)
	
	_rooms[room.id] = room
	
	_state.add_child(room)
	client.get_parent().remove_child(client)
	room.add_child(client)
	
	_send_create_room_response_succeed(client_id, room.id)

func _send_create_room_response_succeed(client_id: int, room_id: String) -> void:
	network.send_client_packet([client_id], ClientPacket.Response__Room_Created, { 
		succeeded = true,
		room_id = room_id,
	})

func _create_error_response(reason: String) -> Dictionary:
	return {
		succeeded = false,
		reason = reason,
	}

func _disconnect() -> void:
	network.stop_listening()
	_connect.disabled = false
	_disconnect.disabled = true

func _connect() -> void:
	if multiplayer.network_peer.get_connection_status() != NetworkedMultiplayerPeer.CONNECTION_DISCONNECTED: return
	var success := network.start_listening_for_clients()
	_connect.disabled = true
	_disconnect.disabled = false

func _on_client_disconnected(id: int) -> void:
	_log('client disconnectd: %d' % id)
	
	var node := _clients.get(id, null) as Node
	assert(node, 'client can only be disconnected if connected previously')
	if not node: return
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
