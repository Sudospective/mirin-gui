extends Control

const TEMPLATE_URL: String = 'https://api.github.com/repos/xerool/notitg-mirin'

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

var mods: Array
var actors: Array

var modfile: String

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
	btn_new.connect("pressed", self, "folder_browse", ['new'])
	btn_open.connect("pressed", self, "folder_browse", ['open'])
	file_browser.connect("dir_selected", self, "folder_select")
	mod_type.connect("item_selected", self, "type_select")
	btn_insert.connect("pressed", self, "_on_insert")
	
	font.font_data = styles.reg
	font.size = 64
	aux = 0
	file_browser.set_access(FileDialog.ACCESS_FILESYSTEM)
	mod_type.add_item('Set')
	mod_type.add_item('Ease')
	mod_type.add_item('Add')
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
	set_panel.show()
	proj_path = path
	if browse_type == 'new':
		for file_dir in ['', 'lua', 'template']:
			var http = HTTPRequest.new()
			add_child(http)
			http.connect("request_completed", self, "_template_response")
			var headers = [
				'Accept: application/vnd.github.v3+json'
			]
			http.request(TEMPLATE_URL + '/contents/' + file_dir, headers, HTTPClient.METHOD_GET)
	else:
		open_file('lua/mods.xml')
		mod_type.set("disabled", false)
		mod_name.set_editable(true)
		mod_perc.set_editable(true)
		btn_insert.set("disabled", false)

func _template_response(result, response_code, headers, body):
	if response_code != HTTPClient.RESPONSE_OK:
		push_error('Failed to download template: ' + str(response_code))
		return
	var res: String = body.get_string_from_utf8()
	if !res:
		push_error('Unable to get HTTP data from repository response.')
		return
	var data: Array = parse_json(res)
	if data:
		var template_tree: Dictionary
		var dir = Directory.new()
		dir.open(proj_path)
		dir.make_dir('lua')
		dir.make_dir('template')
		for item in data:
			var http = HTTPRequest.new()
			add_child(http)
			http.connect("request_completed", self, "_file_downloaded", [item.path])
			if item.download_url:
				http.request(item.download_url, [], HTTPClient.METHOD_GET)
	mod_type.set("disabled", false)
	mod_name.set_editable(true)
	mod_perc.set_editable(true)
	btn_insert.set("disabled", false)

func _file_downloaded(result, response_code, headers, body, file_dir):
	var f = File.new()
	f.open(proj_path + '/' + file_dir, File.WRITE_READ)
	f.store_buffer(body)
	f.close()
	if file_dir == 'lua/mods.xml':
		open_file(file_dir)

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
	var m_name: String = '\'' + mod_name.get_text() + '\''
	if cur_panel != set_panel:
		m_length = cur_panel.get_node("ModLength").get_line_edit().get_text()
		m_ease = cur_panel.get_node("ModEase").get_item_text(cur_panel.get_node("ModEase").get_selected())
	insert_mod(m_type, m_start, m_length, m_ease, m_perc, m_name)

func insert_mod(type: String, start: String, length: String, easefunc: String, percent: String, mod: String):
	var modline: String
	if type != 'set':
		modline = '%s {%s, %s, %s, %s, %s}' % [type, start, length, easefunc, percent, mod]
	else:
		modline = '%s {%s, %s, %s}' % [type, start, percent, mod]
	mods.append('\t' + modline)

func insert_actor(actortype: String, actorname: String):
	var actorline: String
	actorline = ("""
	<%s
		Name = %s
	/>""") % [actortype, actorname]
	actors.append(actorline)

func open_file(file):
	var f = File.new()
	f.open(proj_path + '/' + file, File.READ)
	modfile = f.get_as_text()
	f.close()

func save_to_file(file):
	var split_file: Array = modfile.split('\n')
	print(split_file.find('end)"'))
	var mod_index = split_file.find('end)"') - 2
	var actor_index = split_file.find('</children>')
	for modline in mods:
		split_file.insert(mod_index, modline)
		mod_index += 1
	for actorline in actors:
		split_file.insert(actor_index, actorline)
		actor_index += 1
	var joined_file: PoolStringArray = PoolStringArray(split_file)
	modfile = joined_file.join('\n')
	
	var f = File.new()
	f.open(proj_path + '/' + file, File.WRITE)
	f.store_string(modfile)
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
		save_to_file('lua/mods.xml')

func _draw():
	draw_string(font, Vector2(20, 72), text, color)
	pass
