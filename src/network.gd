class_name __Network__
extends Node

signal client_request_received(request, args)
signal server_packet_received(response, params)

const SERVER_IP := 'localhost'
const SERVER_PORT := 8888
const SERVER_ID := 1

func request_from_server(request: String, args := []) -> void:
	assert(multiplayer.get_network_unique_id() != SERVER_ID, 'must be a client')
	if multiplayer.get_network_unique_id() == SERVER_ID: return
	rpc_id(SERVER_ID, '_emit_client_request_signal', request, args)
	
func send_client_packet(clients: PoolIntArray, packet: String, results := {}) -> void:
	assert(multiplayer.get_network_unique_id() == SERVER_ID, 'should only be called from server')
	assert(not SERVER_ID in clients, 'should not be sending response to itself')
	
	for id in clients:
		rpc_id(id, '_emit_server_response_signal', packet, results)

remote func _emit_client_request_signal(request: String, args: Array) -> void:
	emit_signal('client_request_received', multiplayer.get_rpc_sender_id(), request, args)

remote func _emit_server_response_signal(packet: String, results: Dictionary) -> void:
	emit_signal('server_packet_received', packet, results)

func start_connecting_to_server() -> bool:
	var client := NetworkedMultiplayerENet.new()
	var error := client.create_client(SERVER_IP, SERVER_PORT)
	
	if error != OK: return false
	
	multiplayer.set_network_peer(client)
	
	return true

func stop_connection_to_server() -> void:
	if multiplayer.network_peer.get_connection_status() != NetworkedMultiplayerPeer.CONNECTION_DISCONNECTED:
		multiplayer.network_peer.close_connection()
	multiplayer.set_network_peer(null)

func start_listening_for_clients() -> bool:
	var server := NetworkedMultiplayerENet.new()
	var error := server.create_server(SERVER_PORT, 10)
	
	if error != OK: return false
	
	multiplayer.set_network_peer(server)
	
	return true

func stop_listening() -> void:
	var server := multiplayer.network_peer as NetworkedMultiplayerENet
	server.close_connection()





