class_name Level
extends Spatial

export(NodePath) var _players_node_path := NodePath()

onready var _players_node := get_node_or_null(_players_node_path)

func _ready() -> void:
	assert(_players_node, 'must be set')

func get_players() -> Array:
	return _players_node.get_children()
