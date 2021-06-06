extends AnimationPlayer

onready var _movement := NodE.get_sibling(self, Movement) as Movement

func _ready() -> void:
	if not _movement: return
	
	_movement.connect('started_moving', self, '_on_started_moving')
	_movement.connect('stopped_moving', self, '_on_stopped_moving')
	play('idle')

func _on_started_moving() -> void:
	play('walk')

func _on_stopped_moving() -> void:
	play('idle')
