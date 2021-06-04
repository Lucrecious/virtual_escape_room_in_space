class_name Server_Room
extends Node

var display_name := '<untitled>'
var id := ''

func _ready() -> void:
	assert(not id.empty(), 'id must be valid (not empty)')
