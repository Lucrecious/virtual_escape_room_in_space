class_name Server_Room
extends Node

var display_name := '<untitled>'
var id := ''

func _ready() -> void:
	assert(not id.empty(), 'id must be valid (not empty)')

func get_clients() -> Array:
	var clients := []
	for child in get_children():
		if not child is Server_Client: continue
		clients.push_back(child)
	
	return clients
