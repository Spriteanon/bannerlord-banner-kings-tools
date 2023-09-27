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

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _confirm():
	var result : Error = file_importer._import_file(type_selector.selected, full_path.text, file_test, mode)
	if result == OK:
		_clear_window()
