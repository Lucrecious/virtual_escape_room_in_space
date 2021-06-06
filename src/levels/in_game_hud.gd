class_name HUD_InGame
extends Control

export(NodePath) var _player_path := NodePath()

var _entity: Spatial

onready var _player := get_node_or_null(_player_path) as PlayerDummy
onready var _tooltip3d = $Tooltip as Label

func _ready() -> void:
	if not _player: return
	
	var player := _player
	_player = null
	set_player(player)

func set_player(player: PlayerDummy) -> void:
	if player == _player: return
	
	if _player:
		var detector := NodE.get_child(_player, EntityDetector) as EntityDetector
		if not detector: return
		detector.disconnect('entity_detected', self, '_on_entity_detected')
		_player.disconnect('tree_exiting', self, 'set_player')
	
	_player = player
	
	if _player:
		var detector := NodE.get_child(_player, EntityDetector) as EntityDetector
		if not detector: return
		detector.connect('entity_detected', self, '_on_entity_detected', [detector])
		_player.connect('tree_exiting', self, 'set_player', [null])

func _on_entity_detected(detector: EntityDetector) -> void:
	var entity := detector.get_collider()
	if not entity:
		set_3d_tooltip(null, '')
		return
	
	var text := NodE.get_child(entity, TooltipText) as TooltipText
	if not text:
		set_3d_tooltip(null, '')
		return
	
	set_3d_tooltip(entity, text.text)

func set_3d_tooltip(entity: Spatial, text: String) -> void:
	if not entity:
		_entity = null
		_tooltip3d.text = ''
		return
	
	var display_position := NodE.get_child(entity, TooltipPosition) as TooltipPosition
	_entity = display_position if display_position else _entity
	_tooltip3d.text = text

func _process(delta: float) -> void:
	if not _entity: return
	var camera := get_viewport().get_camera()
	var v2 := camera.unproject_position(_entity.global_transform.origin)
	_tooltip3d.rect_global_position = v2 - _tooltip3d.rect_size.x / 2.0 * Vector2.RIGHT
	_tooltip3d.text 
	
	var tip_rect := Rect2(_tooltip3d.rect_global_position, _tooltip3d.rect_size)
	var view_rect := get_viewport_rect()
	if tip_rect.position.x < view_rect.position.x:
		tip_rect.position.x = view_rect.position.x
	elif tip_rect.position.x + tip_rect.size.x > view_rect.position.x + view_rect.size.x:
		tip_rect.position.x = view_rect.position.x + view_rect.size.x - tip_rect.size.x
	
	if tip_rect.position.y < view_rect.position.y:
		tip_rect.position.y = view_rect.position.y
	elif tip_rect.position.y + tip_rect.size.y > view_rect.position.y + view_rect.size.y:
		tip_rect.position.y = view_rect.position.y + view_rect.size.y - tip_rect.position.y
	
	_tooltip3d.rect_global_position = tip_rect.position


