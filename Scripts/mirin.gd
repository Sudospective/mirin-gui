extends Control

var font: DynamicFont = DynamicFont.new()
var label: Label = Label.new()
var color: Color = Color.white
var text: String = ''
var aux: float = 0
var proj_path: String = ''
var styles: Dictionary = {
	'reg': load('res://Assets/Fonts/UbuntuMono-Regular.ttf'),
	'ital': load('res://Assets/Fonts/UbuntuMono-Italic.ttf'),
	'bold': load('res://Assets/Fonts/UbuntuMono-Bold.ttf'),
}
var browse_type: String = ''

var mods: Dictionary = {
'header': '<Mods Type = "ActorFrame" LoadCommand = "%xero(function(self)',
'body': (
"""
	for pn = 1, 2 do
		setupJudgeProxy(PJ[pn], P[pn]:GetChild('Judgment'), pn)
		setupJudgeProxy(PC[pn], P[pn]:GetChild('Combo'), pn)
	end
	for pn = 1, #PP do
		PP[pn]:SetTarget(P[pn])
		P[pn]:hidden(1)
	end
\n"""
),
'footer': '\nend)">\n'
}
var actors: Dictionary = {
'header': '<children>',
'body': (
"""
	<Layer Type = "ActorProxy" Name = "PP[1]" />
	<Layer Type = "ActorProxy" Name = "PP[2]" />
	<Layer Type = "ActorProxy" Name = "PC[1]" />
	<Layer Type = "ActorProxy" Name = "PC[2]" />
	<Layer Type = "ActorProxy" Name = "PJ[1]" />
	<Layer Type = "ActorProxy" Name = "PJ[2]" />
"""
),
'footer': '</children></Mods>'
}

onready var btn_new: Button = get_node("Workspace/ButtonNew")
onready var btn_open: Button = get_node("Workspace/ButtonOpen")
onready var file_browser: FileDialog = get_node("Workspace/FileBrowser")
onready var mod_type: OptionButton = get_node("Workspace/ModPanel/ModType")
onready var mod_perc: SpinBox = get_node("Workspace/ModPanel/ModPerc")
onready var mod_name: LineEdit = get_node("Workspace/ModPanel/ModName")
onready var set_panel: Panel = get_node("Workspace/ModPanel/SetPanel")
onready var ease_panel: Panel = get_node("Workspace/ModPanel/EasePanel")
onready var add_panel: Panel = get_node("Workspace/ModPanel/AddPanel")
onready var cur_panel: Panel = set_panel
onready var btn_insert: Button = get_node("Workspace/ModPanel/ModInsert")


func status_text(condition, good_text: String, bad_text: String) -> void:
	if condition:
		#imgui.text_colored(good_text, .7, 1, .6)
		pass
	else:
		#imgui.text_colored(bad_text, 1, .7, .6)
		pass

func draw_circle_arc(center, radius, angle_from, angle_to, color):
	var nb_points = 32
	var points_arc = PoolVector2Array()

	for i in range(nb_points + 1):
		var angle_point = deg2rad(angle_from + i * (angle_to-angle_from) / nb_points - 90)
		points_arc.push_back(center + Vector2(cos(angle_point), sin(angle_point)) * radius)

	for index_point in range(nb_points):
		draw_line(points_arc[index_point], points_arc[index_point + 1], color)

func _ready():
	font.font_data = styles.reg
	font.size = 64
	aux = 0
	btn_new.connect("pressed", self, "folder_browse", ['new'])
	btn_open.connect("pressed", self, "folder_browse", ['open'])
	file_browser.connect("dir_selected", self, "folder_select")
	file_browser.set_access(FileDialog.ACCESS_FILESYSTEM)
	mod_type.add_item('Set')
	mod_type.add_item('Ease')
	mod_type.add_item('Add')
	mod_type.connect("item_selected", self, "type_select")
	btn_insert.connect("pressed", self, "_on_insert")
	for item in [
		'instant',
		'linear',
		'inSine',
		'outSine',
		'inOutSine',
		'inCubic',
		'outCubic',
		'inOutCubic',
		'inQuad',
		'outQuad',
		'inOutQuad',
	]:
		get_node("Workspace/ModPanel/EasePanel/ModEase").add_item(item)
		get_node("Workspace/ModPanel/AddPanel/ModEase").add_item(item)
	set_panel.hide()
	ease_panel.hide()
	add_panel.hide()
	mod_type.set("disabled", true)
	mod_name.set_editable(false)
	mod_perc.set_editable(false)
	btn_insert.set("disabled", true)
	cur_panel = set_panel

func folder_browse(mode):
	file_browser.popup_centered()
	browse_type = mode

func folder_select(path):
	mod_type.set("disabled", false)
	mod_name.set_editable(true)
	mod_perc.set_editable(true)
	btn_insert.set("disabled", false)
	set_panel.show()
	proj_path = path
	match browse_type:
		'new':
			pass
		'open':
			pass

func type_select(idx):
	match mod_type.get_item_text(idx):
		'Set':
			set_panel.show()
			ease_panel.hide()
			add_panel.hide()
			cur_panel = set_panel
		'Ease':
			set_panel.hide()
			ease_panel.show()
			add_panel.hide()
			cur_panel = ease_panel
		'Add':
			set_panel.hide()
			ease_panel.hide()
			add_panel.show()
			cur_panel = add_panel

func _on_insert():
	var m_type: String = mod_type.get_item_text(mod_type.get_selected()).to_lower()
	var m_start: String = cur_panel.get_node("ModStart").get_line_edit().get_text()
	var m_length: String = '0'
	var m_ease: String = 'instant'
	var m_perc: String = mod_perc.get_line_edit().get_text()
	var m_name: String = mod_name.get_text()
	if cur_panel != set_panel:
		m_length = cur_panel.get_node("ModLength").get_line_edit().get_text()
		m_ease = cur_panel.get_node("ModEase").get_item_text(cur_panel.get_node("ModEase").get_selected())
	insert_mod(m_type, m_start, m_length, m_ease, m_perc, m_name)

func insert_mod(type, start, length, easefunc, percent, mod):
	var modline: String
	if type != 'set':
		modline = (
			type + ' {' +
			start + ', ' +
			length + ', ' +
			easefunc + ', ' +
			percent + ', ' +
			'\'' + mod + '\'}'
		)
	else:
		modline = (
			type + ' {' +
			start + ', ' +
			percent + ', ' +
			'\'' + mod + '\'}'
		)
	mods.body += '\t' + modline + '\n'

func save_to_file(file, data):
	var f = File.new()
	f.open(proj_path + '/' + file, File.WRITE)
	f.store_string(data)
	f.close()

func print_string(string: String):
	for letter in string:
		if len(text) < len(string):
			text += letter
			yield(get_tree().create_timer(0.06), 'timeout')
			update()

func _process(delta):
	aux += 5
	color.r = (sin(deg2rad(aux)) * 0.5) + 0.5
	color.g = (sin(deg2rad(aux) + 90) * 0.5) + 0.5
	color.b = (sin(deg2rad(aux) + 180) * 0.5) + 0.5
	update()

func _input(event):
	if proj_path != '' and event.is_action_pressed("save_to_file"):
		var compiled_mods = (
			mods.header +
			mods.body +
			mods.footer
		)
		var compiled_actors = (
			actors.header +
			actors.body +
			actors.footer
		)
		var mods_xml = compiled_mods + compiled_actors
		save_to_file('mirin-gui.xml', mods_xml)

func _draw():
	draw_string(font, Vector2(20, 72), text, color)
	pass
