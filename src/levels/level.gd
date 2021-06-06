class_name Level
extends Spatial

const player_local_scene := preload('res://src/player/player_local.tscn')
const player_remote_scene := preload('res://src/player/player_remote.tscn')

export(NodePath) var _players_node_path := NodePath()

onready var _players_node := get_node_or_null(_players_node_path)

func _ready() -> void:
	assert(_players_node, 'must be set')

func get_players() -> Array:
	return _players_node.get_children()

func add_player_local() -> PlayerDummy:
	var player := player_local_scene.instance() as PlayerDummy
	_players_node.add_child(player)
	return player

func add_player_dummy() -> PlayerDummy:
	var player := player_remote_scene.instance() as PlayerDummy
	_players_node.add_child(player)
	return player




