extends PanelContainer

@export var full_path : LineEdit
@export var file_test : RichTextLabel

@export_enum("XMLParser:1", "Custom:2") var mode = 2

var file_exporter : FileExporter

func _ready():
	file_exporter = FileExporter.new()

func _clear_window():
	full_path.text = ""
	file_test.text = ""
	hide()

func _confirm():
	file_exporter._export()

func _on_export_pressed():
	pass # Replace with function body.
