extends Node

onready var _log := $Margin/Control/Log as Label

onready var _connect := $Margin/Control/Connect as Button
onready var _disconnect := $Margin/Control/Disconnect as Button

func _ready() -> void:
	multiplayer.connect('network_peer_connected', self, '_on_client_connected')
	multiplayer.connect('network_peer_disconnected', self, '_on_client_disconnected')
	
	var success := Network.start_listening_for_clients(self)
	if success:
		_disconnect.connect('pressed', self, '_disconnect')
		_connect.connect('pressed', self, '_connect')
		_connect.disabled = true # we already tried to connect
	else:
		var dialog := Popups.create_alert(get_viewport())
		dialog.appear("Unable to start listening to clients.", AlertDialog.ERROR_NETWORK)
	

func _disconnect() -> void:
	Network.stop_listening(self)
	_connect.disabled = false
	_disconnect.disabled = true

func _connect() -> void:
	if multiplayer.network_peer.get_connection_status() != NetworkedMultiplayerPeer.CONNECTION_DISCONNECTED: return
	var success := Network.start_listening_for_clients(self)
	_connect.disabled = true
	_disconnect.disabled = false

func _on_client_disconnected(id: int) -> void:
	_log('client disconnectd: %d' % id)

func _on_client_connected(id: int) -> void:
	_log('client connected: %d' % id)

func _log(text: String) -> void:
	_log.text = (text + '\n\n' + _log.text).left(2000)
