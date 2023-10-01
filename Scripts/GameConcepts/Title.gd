extends RichTextLabel

class_name Title

var id : String
var title_name : String
var tier : int
var de_jure_vassals : Array
var de_jure_owner : String = ""
var de_jure_liege : Title

#For now only exists in this editor
var capital : Settlement
var color : Color
var open : bool = false

func _get_color(needed_tier : int):
	if needed_tier > tier and de_jure_liege != null:
		return de_jure_liege._get_color(needed_tier)
	return color

func _get_owner() -> String:
	if de_jure_owner != "":
		return EncyclopediaManager._get_clan_name(de_jure_owner)
	else:
		return de_jure_liege._get_owner()

# 0 = Same Title , 1 = Same Barony, 2 = Same County, 3 = Same Duchy,
# 4 = Same Kingdom, 5 = Same Empire, 6 = Different Nations
func _get_relationship(other : Title) -> int:
	var ret = _check_relationship_down(other)
	if ret != 7:
		if ret == 1 and other.tier == 0:
			return 0
		return ret
	if de_jure_liege != null:
		return _check_relationship_up(self, other)
	return 7
	
func _check_relationship_up(previous : Title, other : Title) -> int:
	if other == self:
		if previous.tier == 0:
			return 1
		return tier
	for vassal in de_jure_vassals:
		if vassal != previous:
			var ret = vassal._check_relationship_down(other)
			if ret != 7:
				if ret == 1 and other.tier == 0:
					return 1
				return tier
	if de_jure_liege != null:
		return de_jure_liege._check_relationship_up(self, other)
	return 7

func _check_relationship_down(other : Title, depth : int = 1) -> int:
	if other == self:
		return depth + tier
	for vassal in de_jure_vassals:
		var ret = vassal._check_relationship_down(other, depth+1)
		if ret != 7:
			return ret
	return 7

func _get_all_vassals() -> Array:
	var ret : Array
	for vassal in de_jure_vassals:
		ret.append(vassal)
		ret.append_array(_get_all_vassals())
	return ret

func _get_contents():
	text = "[url=\"" + id + "\"][font_size=20]" + title_name + "[/font_size][/url]\n"
	if(open):
		text += "	ID: " + id + "\n"
		text += "	Tier: " + EncyclopediaManager.num_to_tier[tier] + "\n"
		text += "	De Jure Owner: " + _get_owner() + "\n"
		if de_jure_vassals.size() > 0:
			text += "	De Jure Vassals:\n"
			for vassal in de_jure_vassals:
				var vassal_contents = vassal._get_contents().split("\n", false)
				for line in vassal_contents:
					text += "	" + line + "\n"
	return text

func _update_contents():
	if de_jure_liege == null:
		visible = true
		_get_contents()
	else:
		visible = false

func _on_meta_clicked(meta):
	EncyclopediaManager.titles[meta].open = !EncyclopediaManager.titles[meta].open
	_update_contents()
