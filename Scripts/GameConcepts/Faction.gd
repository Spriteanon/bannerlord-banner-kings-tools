extends EncyclopediaItem

class_name Faction

func _get_neccessary_keys():
	return ["id", "name", "tier", "culture", "super_faction"]


func _update_contents():
	var have_everything = true
	for key in _get_neccessary_keys():
		if !data.has(key):
			have_everything = false
	if !have_everything:
		return
	
	text = "[url=\"expand\"][font_size=20]" + _get_name() + "[/font_size][/url]\n"
	title_length = _get_name().length()
	expanded = false
	visible_characters = title_length
	
	text += "ID: " + data["id"] + "\n"
	text += "Raw Name: " + data["name"] + "\n"
	text += "Culture: " + data["culture"] + "\n"
	text += "Tier: " + data["tier"] + "\n"
	text += "Faction: " + data["super_faction"] + "\n"
