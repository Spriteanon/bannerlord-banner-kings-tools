extends PanelContainer

@export var type_selector : OptionButton
@export var full_path : LineEdit
@export var file_test : RichTextLabel

@export_enum("XMLParser:1", "Custom:2") var mode = 2

@export var manager : EncyclopediaManager

var file_importer : FileImporter

func _ready():
	file_importer = FileImporter.new(manager)

func _clear_window():
	type_selector.selected = -1
	full_path.text = ""
	file_test.text = ""
	hide()

func _test_file():
	file_importer._import_file(type_selector.selected, full_path.text, file_test, mode, true)

func _import_vanilla():
	if full_path.text.ends_with("\""):
		full_path.text = full_path.text.substr(0,full_path.text.length()-1)
	var result : Error = file_importer._import_file(1, full_path.text+"\\Modules\\SandBox\\ModuleData\\spclans.xml", file_test, mode)
	if result != OK:
		return
	result = file_importer._import_file(2, full_path.text+"\\Modules\\SandBox\\ModuleData\\settlements.xml", file_test, mode)
	if result != OK:
		return
	result = file_importer._import_file(0, full_path.text+"\\Modules\\SandBox\\ModuleData\\Languages\\std_settlements_xml.xml", file_test, mode)
	if result != OK:
		return
	result = file_importer._import_file(0, full_path.text+"\\Modules\\SandBox\\ModuleData\\Languages\\std_spclans_xml.xml", file_test, mode)
	if result != OK:
		return
	_clear_window()

func _confirm():
	var result : Error = file_importer._import_file(type_selector.selected, full_path.text, file_test, mode)
	if result == OK:
		_clear_window()
