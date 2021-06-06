class_name PlayerDummy
extends KinematicBody

signal display_name_changed()

onready var camera := $Pivot/Camera as Camera
onready var animation_player := $AnimationTree as AnimationTree

