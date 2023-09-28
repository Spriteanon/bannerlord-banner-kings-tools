extends RichTextLabel

class_name EncyclopediaItem

@export var title_length : int = -1
var expanded : bool = false

var data : Dictionary

static func _get_neccessary_keys() -> Array:
	return []

static func _get_optional_keys() -> Array:
	return []

static func _get_used_keys() -> Array:
	return []
	
func _setup(data : Dictionary):
	self.data = data
	name = _get_name()

func _ready():
	if expanded:
		_toggle_expanded()

func _get_name():
	return EncyclopediaManager._get_name_from_raw(data["name"])

func _update_contents():
	var have_everything = true
	for key in _get_neccessary_keys():
		if !data.has(key):
			have_everything = false
	if !have_everything:
		return

func _toggle_expanded():
	if(expanded):
		visible_characters = title_length
	else:
		visible_characters = -1
	expanded = !expanded

func _on_meta_clicked(meta):
	if meta == "expand":
		_toggle_expanded()
