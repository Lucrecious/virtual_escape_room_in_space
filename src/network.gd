extends Node

signal client_request_received(request, args)

const SERVER_IP := 'localhost'
const SERVER_PORT := 8888
const SERVER_ID := 1

func request_from_server(request: int, args := []) -> void:
	rpc_id(SERVER_ID, '_emit_client_request_signal', args)

remote func _emit_client_request_signal(request: int, args: Array) -> void:
	emit_signal('client_request_received', request, args)

func start_connecting_to_server(client_node: Node) -> bool:
	var client := NetworkedMultiplayerENet.new()
	var error := client.create_client(SERVER_IP, SERVER_PORT)
	
	if error != OK: return false
	
	client_node.multiplayer.set_network_peer(client)
	
	return true

func stop_connection_to_server(client_node: Node) -> void:
	if client_node.multiplayer.network_peer.get_connection_status() != NetworkedMultiplayerPeer.CONNECTION_DISCONNECTED:
		client_node.multiplayer.network_peer.close_connection()
	client_node.multiplayer.set_network_peer(null)

func start_listening_for_clients(server_node: Node) -> bool:
	var server := NetworkedMultiplayerENet.new()
	var error := server.create_server(SERVER_PORT, 10)
	
	if error != OK: return false
	
	server_node.multiplayer.set_network_peer(server)
	
	return true

func stop_listening(server_node: Node) -> void:
	var server := server_node.multiplayer.network_peer as NetworkedMultiplayerENet
	server.close_connection()





