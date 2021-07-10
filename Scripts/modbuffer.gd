extends ColorRect

onready var gui = get_tree().get_current_scene()
onready var stack = get_node("ListScroll/Container")


func _ready():
	gui.connect("add_to_modlist", self, "_on_modlist_add")

func _on_modlist_add(type: String, modline: String):
	var mod: Button = Button.new()
	mod.set_custom_minimum_size(Vector2(192, 64))
	mod.set_text(modline)
	stack.add_child(mod)
	mod.connect("pressed", self, "delete_mod", [stack.get_child_count() - 1])
	print('Added ' + type + ' mod to modlist.')
	pass

func delete_mod(idx):
	gui.mods.remove(idx)
	stack.get_child(idx).queue_free()
