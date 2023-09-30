extends TabContainer

class_name EncyclopediaManager

const tier_to_num = { "Lordship":0, "Barony":1, "County":2, "Duchy":3, "Kingdom":4, "Empire":5}
const num_to_tier = { 0:"Lordship", 1:"Barony", 2:"County", 3:"Duchy", 4:"Kingdom", 5:"Empire"}

static var settlements : Dictionary

static var clans : Dictionary

static var localizations : Dictionary

static var titles : Dictionary

@export var settlements_container : Container
var settlements_sort_method : int = 0
@export var clans_container : Container
var clans_sort_method : int = 0
@export var titles_container : Container
var titles_sort_method : int = 0

var settlement_entry = preload("res://Scenes/UI Elements/Settlement Entry.tscn")
var clan_entry = preload("res://Scenes/UI Elements/Clan Entry.tscn")
var title_entry = preload("res://Scenes/UI Elements/Title Entry.tscn")


# 0 = By Name, 1 = By Tier then Name, 2 = By Culture
var settlement_sort_methods = {
	0: func(a : Settlement, b : Settlement):
		return a._get_name().naturalnocasecmp_to(b._get_name()) < 0,
	1: func(a : Settlement, b : Settlement):
		if a.data["tier"] == b.data["tier"]:
			return a._get_name().naturalnocasecmp_to(b._get_name()) < 0
		else:
			return tier_to_num[a.data["tier"]] - tier_to_num[b.data["tier"]] < 0,
	2: func(a : Settlement, b : Settlement):
		if a.data["culture"] == b.data["culture"]:
			return a._get_name().naturalnocasecmp_to(b._get_name()) < 0
		else:
			return a.data["culture"].naturalnocasecmp_to(b.data["culture"]) < 0}

# 0 = By Name, 1 = By Tier then Name, 2 = By Culture, 3 = By Super Faction
var clan_sort_methods = {
	0: func(a : Faction, b : Faction):
		return a._get_name().naturalnocasecmp_to(b._get_name()) < 0,
	1: func(a : Faction, b : Faction):
		if a.data["tier"] == b.data["tier"]:
			return a._get_name().naturalnocasecmp_to(b._get_name()) < 0
		else:
			return a.data["tier"].naturalnocasecmp_to(b.data["tier"]) > 0,
	2: func(a : Faction, b : Faction):
		return a.data["culture"].naturalnocasecmp_to(b.data["culture"]) < 0,
	3: func(a : Faction, b : Faction):
		if a.data["super_faction"] == b.data["super_faction"]:
			return a._get_name().naturalnocasecmp_to(b._get_name()) < 0
		else:
			return a.data["super_faction"].naturalnocasecmp_to(b.data["super_faction"]) < 0}

func _set_settlements_sorting_method(method : int):
	settlements_sort_method = method
	_sort_settlements()

func _set_clans_sorting_method(method : int):
	clans_sort_method = method
	_sort_clans()

func _sort_settlements():
	Toolbox._sort_children_of_node(settlements_container, settlement_sort_methods[settlements_sort_method])

func _sort_clans():
	Toolbox._sort_children_of_node(clans_container, clan_sort_methods[clans_sort_method])

func _reset_titles():
	for title in titles.values():
		title.de_jure_vassals.clear()
		title.de_jure_liege = null
		title.de_jure_owner = ""

func _update_titles():
	for title in titles.values():
		title._update_contents()

func _update_settlements():
	for settlement in settlements.values():
		settlement["node"]._update_contents()

func _update_clans():
	for clan in clans.values():
		clan["node"]._update_contents()

func _add_updates(data : Dictionary):
	for settlement in data["settlements"].values():
		settlements[settlement["id"]][settlement["property"]] = settlement["new_value"]
	for clan in data["clans"]:
		clans[clan["id"]][clan["property"]] = clan["new_value"]
	for localization in data["localizations"]:
		localizations[localization["id"]][localization["property"]] = localization["new_value"]
	_reset_titles()
	_update_clans()
	_update_settlements()
	_sort_settlements()
	_update_titles()

func _add_localization(data : Dictionary):
	for key in data.keys():
		localizations[key] = data[key]
	_reset_titles()
	_update_clans()
	_update_settlements()
	_sort_settlements()
	_update_titles()

func _add_settlements(data : Dictionary):
	for key in data.keys():
		var settlement : Dictionary = data[key]
		if settlements.has(key):
			var sett_keys = settlement.keys()
			for sett_key in sett_keys:
				settlements[key][sett_key] = settlement[sett_key]
		else:
			settlements[key] = settlement
			var new_entry : Settlement = settlement_entry.instantiate()
			new_entry._setup(settlement)
			new_entry.name = key
			settlements_container.add_child(new_entry)
			settlement["node"] = new_entry
			var new_title_entry = title_entry.instantiate()
			titles[key] = new_title_entry
			new_title_entry.id = key
			new_title_entry.capital = new_entry
			new_entry.title = new_title_entry
			new_title_entry.name = key
			titles_container.add_child(new_title_entry)
	_reset_titles()
	_update_settlements()
	_update_clans()
	_sort_settlements()
	_update_titles()

func _add_clans(data : Dictionary):
	for key in data.keys():
		var clan : Dictionary = data[key]
		if clans.has(key):
			var clan_keys = clans.keys()
			for clan_key in clan_keys:
				clans[key][clan_key] = clan[clan_key]
		else:
			clans[key] = clan
			var new_entry : Faction = clan_entry.instantiate()
			new_entry._setup(clan)
			new_entry.name = key
			clans_container.add_child(new_entry)
			clan["node"] = new_entry
	_reset_titles()
	_update_clans()
	_update_settlements()
	_sort_clans()
	_update_titles()

static func _get_owner_of_other(settlement_id):
	return settlements[settlement_id]["node"]._get_owner()

static func _fetch_localization(source):
	var loc : int = source.find("{=") + 2
	var loc_id = source.substr(loc, source.substr(loc).find("}"))
	if localizations.has(loc_id):
		return localizations[loc_id]
	else:
		if source.contains("}"):
			return source.substr(source.find("}")+1) + " (ML!)"
		else:
			return source + " (ML!)"

static func _get_name_from_raw(raw_name):
	if raw_name.contains("{="):
		return _fetch_localization(raw_name)
	return raw_name + " (NLF)"

static func _get_settlement_name_from_id(id : String):
	if settlements.has(id):
		return _get_name_from_raw(settlements[id]["name"])
	else:
		return "<Missing Settlement>"

static func _get_clan_name(id : String):
	if(clans.has(id)):
		return _get_name_from_raw(clans[id]["name"])
	else:
		return id + " (Not imported)"
