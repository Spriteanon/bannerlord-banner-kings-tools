extends RichTextLabel

class_name Title

enum Contract_Types { FEUDAL = 0, TRIBAL = 1, IMPERIAL = 2, REPUBLIC = 3, NO_CONTRACT = 4}

const contract_to_string = { Contract_Types.FEUDAL:"feudal", Contract_Types.TRIBAL:"tribal", Contract_Types.IMPERIAL:"imprial",Contract_Types.REPUBLIC:"republic" }

var id : String
var title_name : String
var tier : int
var de_jure_vassals : Array
var de_jure_owner : String = ""
var de_jure_liege : Title
var contract_type : Contract_Types = Contract_Types.NO_CONTRACT

#For now only exists in this editor
var capital : Settlement
var color : Color
var open : bool = false

const no_owner : String = "No owner set"

func _is_part_of_title(other : Title) -> bool:
	if other == self:
		return true
	if de_jure_liege != null:
		return de_jure_liege._is_part_of_title(other)
	return false

func _get_liege_at_tier(_tier : int):
	if tier == _tier:
		return self
	if de_jure_liege != null:
		return de_jure_liege._get_liege_at_tier(_tier)
	return null

func _get_contract_type():
	if contract_type != Contract_Types.NO_CONTRACT:
		return contract_type
	if de_jure_liege != null:
		return de_jure_liege._get_contract_type()
	return Contract_Types.NO_CONTRACT

func _get_color(needed_tier : int):
	if needed_tier > tier and de_jure_liege != null:
		return de_jure_liege._get_color(needed_tier)
	return color

func _get_owner_id():
	if de_jure_owner != "":
		return de_jure_owner
	else:
		if de_jure_liege == null:
			return no_owner
		var liege_owner = de_jure_liege._get_owner_id()
		if liege_owner != no_owner:
			de_jure_owner = liege_owner
			return de_jure_owner
		return no_owner

func _get_owner() -> String:
	var owner_id = _get_owner_id()
	if owner_id != no_owner:
		return EncyclopediaManager._get_clan_name(owner_id)
	return no_owner

func _get_owner_hero() -> String:
	var hero = EncyclopediaManager.clans[_get_owner_id()]["owner"]
	return hero.substr(hero.find(".")+1)

# 0 = Same Title , 1 = Same Barony, 2 = Same County, 3 = Same Duchy,
# 4 = Same Kingdom, 5 = Same Empire, 6 = Different Nations
func _get_relationship(other : Title) -> int:
	var ret = _check_relationship_down(other)
	if ret != 6:
		return ret
	if de_jure_liege != null:
		if tier == 0 and other.tier == 0 and other.de_jure_liege != null and other.de_jure_liege == de_jure_liege:
			return 1
		return _check_relationship_up(self, other)
	return 6
	
func _check_relationship_up(previous : Title, other : Title) -> int:
	if other == self:
		if previous.tier == 0:
			return 1
		return tier
	for vassal in de_jure_vassals:
		if vassal != previous:
			var ret = vassal._check_relationship_down(other)
			if ret != 6:
				return tier
	if de_jure_liege != null:
		return de_jure_liege._check_relationship_up(self, other)
	return 6

func _check_relationship_down(other : Title, depth : int = 0) -> int:
	if other == self:
		return depth + tier
	for vassal in de_jure_vassals:
		var ret = vassal._check_relationship_down(other, depth+1)
		if ret != 6:
			return ret
	return 6

func _get_all_vassals() -> Array:
	var ret : Array = []
	for vassal in de_jure_vassals:
		ret.append(vassal)
		ret.append_array(_get_all_vassals())
	return ret

func _get_full_title() -> String:
	return EncyclopediaManager.num_to_tier[tier] + " of " + title_name

func _get_contents():
	var shown_title = "[url=\"" + id + "\"][font_size=20]" + _get_full_title() + "[/font_size][/url]"
	if TitleManager.current_mode == 1 and TitleManager.vassal == self:
		text = "[color=yellow]" + shown_title + "[url=\"cancel_vassal\"] [font_size=16]Cancel Vassalization[/font_size][/url][/color]"
	else:
		text = shown_title
		if _get_owner() == no_owner:
			text += " [color=orange][font_size=16]Warning: No Owner Set![/font_size][/color]"
	if TitleManager.current_mode == 1 and TitleManager.vassal.tier == tier-1:
		text += " [color=green][url=\"add_vassal."+id+"\"][font_size=16]Add Vassal[/font_size][/url][/color]"
	elif TitleManager.current_mode == 0:
		if tier < 4 and de_jure_liege == null:
			text += " [color=green][url=\"vassalize\"][font_size=16]Vassalize[/font_size][/url][/color]"
		elif de_jure_liege != null and tier > 0:
			text += " [color=red][url=\"remove_vassal."+id+"\"][font_size=16]Remove Vassal[/font_size][/url][/color]"
			if de_jure_vassals.size() == 0 and de_jure_liege == null:
				text += " [color=red][url=\"delete."+id+"\"][font_size=16]Delete Title[/font_size][/url][/color]"
	if tier > 2:
			text += " [color=cyan][url=\"edit."+id+"\"][font_size=16]Edit Title[/font_size][/url][/color]"
	text += "\n"
	if open:
		text += "	ID: " + id + "\n"
		text += "	Tier: " + EncyclopediaManager.num_to_tier[tier] + "\n"
		text += "	[color=#" + color.to_html() +"]Map Color[/color]\n"
		text += "	De Jure Owner: " + _get_owner()
		if TitleManager.current_mode != 2 and _get_owner() != no_owner and de_jure_liege != null:
			text += " [color=yellow][url=\"set_liege_owner."+id+"\"]Set as Liege Title's Owner[/url][/color]"
		text += "\n"
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

func _add_vassal(vassal : Title):
	if vassal.de_jure_liege != null:
		vassal._remove_liege()
	de_jure_vassals.append(vassal)
	vassal.de_jure_liege = self
	EncyclopediaManager._update_titles()
	Cartographer._update_map()

func _remove_liege():
	de_jure_liege.de_jure_vassals.erase(self)
	de_jure_liege._update_contents()
	de_jure_liege = null
	_update_contents()

func _on_meta_clicked(meta):
	if meta.begins_with("vassalize"):
		TitleManager.current_mode = TitleManager.Mode.ADD_VASSAL
		TitleManager.vassal = self
		EncyclopediaManager._update_titles()
	elif meta.begins_with("add_vassal"):
		var title = EncyclopediaManager.titles[meta.substr(meta.find(".")+1)]
		TitleManager.current_mode = TitleManager.Mode.DISPLAY
		title._add_vassal(TitleManager.vassal)
	elif meta.begins_with("remove_vassal"):
		var title = EncyclopediaManager.titles[meta.substr(meta.find(".")+1)]
		title._remove_liege()
		Cartographer._update_map()
	elif meta.begins_with("cancel_vassal"):
		TitleManager.current_mode = TitleManager.Mode.DISPLAY
		EncyclopediaManager._update_titles()
	elif meta.begins_with("set_liege_owner"):
		var title = EncyclopediaManager.titles[meta.substr(meta.find(".")+1)]
		title.de_jure_liege.de_jure_owner = title.de_jure_owner
		EncyclopediaManager._update_titles()
	elif meta.begins_with("delete"):
		var title = EncyclopediaManager.titles[meta.substr(meta.find(".")+1)]
		EncyclopediaManager._delete_title(title)
	elif meta.begins_with("edit"):
		var title = EncyclopediaManager.titles[meta.substr(meta.find(".")+1)]
		TitleManager.instance._edit_title(title)
	else:
		EncyclopediaManager.titles[meta].open = !EncyclopediaManager.titles[meta].open
		_update_contents()
