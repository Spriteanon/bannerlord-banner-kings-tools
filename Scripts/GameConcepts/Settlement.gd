extends EncyclopediaItem
	
class_name Settlement

var tile : Tile

var title : Title

func _init():
	title = Title.new()
	title.capital = self

func _get_vector() -> Vector2:
	#[sic]
	var rect : Vector2 = Vector2(float(data["posX"]), float(data["posY"]))
	return rect

func _get_neccessary_keys():
	return ["id", "name", "tier", "posX", "posY", "culture", "text"]

func _get_owner():
	if data.has("owner"):
		return EncyclopediaManager._get_owner_of_settlement(data["owner"])

func _get_full_title():
	return data["tier"] + " of " + _get_name()

func _update_contents():
	var have_everything = true
	for key in _get_neccessary_keys():
		if !data.has(key):
			have_everything = false
	if !have_everything:
		return
	
	title.tier = data["tier"]
	title.id = data["id"]
	if data.has("owner"):
		title.de_jure_owner = data["owner"]
	if data.has("bound"):
		title.de_jure_liege = EncyclopediaManager.settlements[data["bound"]]["node"].title
		EncyclopediaManager.settlements[data["bound"]]["node"].title.de_jure_vassals.append(title)
		
	
	text = "[url=\"expand\"][font_size=20]" + _get_full_title() + "[/font_size][/url]\n"
	title_length = _get_full_title().length()
	expanded = false
	visible_characters = title_length
	
	text += "ID: " + data["id"] + "\n"
	text += "Raw Name: " + data["name"] + "\n"
	text += "Coordinates: " + str(data["posX"]) + "," + str(data["posY"]) + "\n"
	text += "Culture: " + data["culture"] + "\n"
	if data.has("owner"):
		text += "Owned by: " + _get_owner() + "\n"
	elif data.has("bound"):
		var bound_name = EncyclopediaManager._get_settlement_name_from_id(data["bound"])
		text += "Bound to: " + bound_name + "\n"
		text += "Owned (through bound fortfication) by: " + EncyclopediaManager._get_owner_of_other(data["bound"]) + "\n"
	
	text += "Encyclopedia text: " + EncyclopediaManager._fetch_localization(data["text"]) + "\n"

func _toggle_expanded():
	if(expanded):
		visible_characters = title_length
	else:
		visible_characters = -1
	expanded = !expanded

func _on_meta_clicked(meta):
	if meta == "expand":
		_toggle_expanded()
