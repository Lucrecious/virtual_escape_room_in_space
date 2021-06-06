extends AnimationTree

onready var _movement := NodE.get_sibling(self, Movement) as Movement

var _caption_to_index := { 'idle' : 0, 'run': 1, 'dance' : 2 }
var _index_to_caption := { 0 : 'idle', 1 : 'run', 2 : 'dance' }

func _ready() -> void:
	#yield(get_tree(), 'idle_frame')
	#var transition = get('parameters/idle_run')
	#print(transition)
	#for i in transition.input_count:
	#	_caption_to_index[transition.get_input_caption(i)] = i
	
	active = true
	play('idle')
	if not _movement: return
	
	_movement.connect('started_moving', self, '_on_started_moving')
	_movement.connect('stopped_moving', self, '_on_stopped_moving')
	
	var controller := NodE.get_sibling(self, Controller) as Controller
	assert(controller, 'must be sibling')
	
	controller.connect('unhandled_input', self, '_on_unhandled_input')

func _on_unhandled_input(event: InputEvent) -> void:
	if current_animation() == 'run': return
	if not event.is_action_pressed('dance'): return
	play('dance')

func play(animation: String) -> void:
	set('parameters/idle_run/current', _caption_to_index.get(animation, 0))

func current_animation() -> String:
	return _index_to_caption.get(get('parameters/idle_run/current'), 'idle')

func _on_started_moving() -> void:
	play('run')

func _on_stopped_moving() -> void:
	play('idle')






