extends Node

var window_size = Vector2(1280, 720)
var window_title = 'Mirin Template GUI Editor'


func _ready():
	ProjectSettings.set_setting('display/window/size', window_size)
	OS.set_window_title(window_title)
