extends Control

class_name TitleManager

@export var encyclopedia : EncyclopediaManager
@export var new_title_button : Button
@export var finalize_edit_button : Button
@export var title_name : LineEdit
@export var title_id : LineEdit
@export var title_level : OptionButton
@export var contract_type : OptionButton
@export var color_slider : HSlider
@export var color_preview : ColorRect

enum Mode { DISPLAY = 0, ADD_VASSAL = 1, EDIT = 2}
static var current_mode : Mode
static var vassal : Title
static var instance

var title_in_edit : Title

func _ready():
	instance = self

func _generate_new_titles():
	# First remove old titles and find Counties
	var to_remove : Array = []
	var counties : Array[Title] = []
	var kingdoms : Array[String] = []
	var kingdom_vassals : Dictionary = {}
	var kingdom_baronies : Dictionary = {}
	for title in EncyclopediaManager.titles.values():
		if title.tier > 2:
			to_remove.append(title)
		else:
			var kingdom = title.capital._get_super_faction()
			if kingdom != null and !kingdoms.has(kingdom):
				kingdoms.append(kingdom)
				kingdom_vassals[kingdom] = []
				kingdom_baronies[kingdom] = []
			if title.tier == 2:
				title.de_jure_liege = null
				counties.append(title)
				kingdom_vassals[title.capital._get_super_faction()].append(title)
			elif title.tier == 1:
				kingdom_baronies[title.capital._get_super_faction()].append(title)
	for title in to_remove:
		EncyclopediaManager._delete_title(title)
	
	# Generate new ones
	for county in counties:
		var new_title : Dictionary = {}
		new_title["name"] = county.title_name
		new_title["id"] = county.id + "_duchy"
		new_title["tier"] = 3
		new_title["color"] = county.color
		new_title["contract"] = Title.Contract_Types.NO_CONTRACT
		var new_duchy = encyclopedia._add_title(new_title)
		new_duchy.de_jure_vassals.append(county)
		county.de_jure_liege = new_duchy
		new_duchy.de_jure_owner = county.de_jure_owner
	for kingdom in kingdoms:
		var new_title : Dictionary = {}
		new_title["name"] = kingdom.substr(kingdom.find(".")+1)
		new_title["id"] = new_title["name"]
		new_title["tier"] = 4
		new_title["color"] = Color.from_hsv(float(kingdoms.find(kingdom))/kingdoms.size(), 0.7, 1)
		new_title["contract"] = Title.Contract_Types.FEUDAL
		var new_kingdom = encyclopedia._add_title(new_title)
		for vassal in kingdom_vassals[kingdom]:
			var duchy = vassal.de_jure_liege
			duchy.de_jure_liege = new_kingdom
			new_kingdom.de_jure_vassals.append(duchy)
			for barony in kingdom_baronies[kingdom]:
				if barony.de_jure_liege == null:
					barony.de_jure_liege = vassal
					vassal.de_jure_vassals.append(barony)
				elif barony.capital._get_vector().distance_squared_to(vassal.capital._get_vector()) < barony.capital._get_vector().distance_squared_to(barony.de_jure_liege.capital._get_vector()):
					barony.de_jure_liege.de_jure_vassals.erase(barony)
					barony.de_jure_liege = vassal
					vassal.de_jure_vassals.append(barony)
		new_kingdom.de_jure_owner = kingdom_vassals[kingdom][0].de_jure_owner
	EncyclopediaManager._update_titles()

func _purge_empty():
	var to_remove : Array = []
	for title in EncyclopediaManager.titles.values():
		if title.tier == 3 and title.de_jure_vassals.size() == 0:
			to_remove.append(title)
			if title.de_jure_liege != null:
				title.de_jure_liege.de_jure_vassals.erase(title)
		if title.tier == 4 and title.de_jure_vassals.size() == 0:
			to_remove.append(title)
			if title.de_jure_liege != null:
				title.de_jure_liege.de_jure_vassals.erase(title)
	for title in to_remove:
		EncyclopediaManager._delete_title(title)
	EncyclopediaManager._update_titles()

func _add_new_title():
	if title_name.text == "" or title_id.text == "" or EncyclopediaManager.titles.has(title_id.text):
		return
	var new_title : Dictionary = {}
	new_title["name"] = title_name.text
	new_title["id"] = title_id.text
	new_title["tier"] = title_level.get_selected_id()+3
	new_title["color"] = color_preview.color
	if contract_type.visible:
		new_title["contract"] = contract_type.get_selected_id()
	else:
		new_title["contract"] = Title.Contract_Types.NO_CONTRACT
	encyclopedia._add_title(new_title)

func _edit_title(title : Title):
	current_mode = Mode.EDIT
	title_in_edit = title
	new_title_button.visible = false
	finalize_edit_button.visible = true
	title_name.text = title.title_name
	title_id.text = title.id
	title_level.visible = false
	color_preview.color = title.color
	color_slider.value = title.color.h
	if title.tier > 3:
		contract_type.selected = title.contract_type
		contract_type.visible = true
	else:
		contract_type.visible = false
	EncyclopediaManager._update_titles()
	
func _finalize_edit():
	current_mode = Mode.DISPLAY
	new_title_button.visible = true
	finalize_edit_button.visible = false
	title_in_edit.title_name = title_name.text
	title_name.text = ""
	EncyclopediaManager.titles.erase(title_in_edit.id)
	title_in_edit.id = title_id.text
	title_id.text = ""
	EncyclopediaManager.titles[title_in_edit.id] = title_in_edit
	title_level.visible = true
	title_in_edit.color = color_preview.color
	color_slider.value = 0
	_update_color(0)
	if contract_type.visible :
		title_in_edit.contract_type = contract_type.selected as Title.Contract_Types
	Cartographer._update_map()

func _update_level(new_level : int):
	contract_type.visible = new_level+3 > 3

func _update_color(new_h : float):
	color_preview.color =Color.from_hsv(new_h, 0.7, 1)
