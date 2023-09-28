class_name FileImporter

var parser = XMLParser.new()

# Number ids for file types:
#-1 : Type not selected
# 0 : Language file
# 1 : lords.xml style
# 2 : settelements.xml style
# 3 : override.xslt style

const unknown_open_error : String = "[b][u]ERROR![/u][/b]
Something went wrong trying to open the file.
Please confirm that the path was correct, and that the file type corresponds to your selection."

var manager : EncyclopediaManager

func _init(manager : EncyclopediaManager):
	self.manager = manager

func _import_file(type : int, full_path : String, label : RichTextLabel, mode, test : bool = false):
	match type:
		-1:
			label.text = "[b]No file type selected.[/b] Please select a type from the dropdown menu."
			return Error.ERR_FILE_CANT_OPEN
		0, 1, 2:
			match mode:
				1:
					return _import_with_parser(type, full_path, label, test)
				2:
					return _import_with_custom(type, full_path, label, test)
		3:
			match mode:
				1:
					pass
				2:
					return _import_updates_custom(full_path, label, test)

func _import_updates_custom(full_path : String, label : RichTextLabel, test: bool):
	var file = FileAccess.open(full_path, FileAccess.READ)
	match FileAccess.get_open_error():
		OK:
			var content = file.get_as_text()
			var arr = content.split("<xsl:template")
			_cull_and_tidy(arr,3)
			var result : Dictionary = _custom_parse_overrides(arr)
			label.text = ""
			if test:
				if result["non-existing"]:
					label.text = "[u][b]WARNING![/b][/u] Some of the overrides are for not yet present elements. These will be ignored.\n\n"
				label.text += result["for_test"]
			else:
				manager._add_updates(result)
		_:
			label.text = unknown_open_error
	return FileAccess.get_open_error()

func _import_with_custom(type : int, full_path : String, label : RichTextLabel, test : bool):
	var file = FileAccess.open(full_path, FileAccess.READ)
	match FileAccess.get_open_error():
		OK:
			var content = file.get_as_text()
			var arr = content.split("<", false)
			_cull_and_tidy(arr, type)
			var result : Dictionary 
			match type:
				0:
					result = _custom_parse_language(arr)
				1:
					result = _custom_parse_clans(arr)
				2:
					result = _custom_parse_settlements(arr)
			if test:
				label.text = result["for_test"]
			else:
				match type:
					0:
						manager._add_localization(result["data"])
					1:
						manager._add_clans(result["data"])
					2:
						manager._add_settlements(result["data"])
		_:
			label.text = unknown_open_error
	return FileAccess.get_open_error()

func _cull_and_tidy(arr : PackedStringArray, type : int):
	var keyword : String
	match type:
		0:
			keyword = "string"
		1:
			keyword = "Faction"
		2:
			keyword = "Settlement"
		3:
			keyword = "Override"
	var to_cull : Array
	var i = 0
	while i < arr.size():
		if arr[i].begins_with("!--"):
			var j = i
			var end_found = false
			while !end_found and j < arr.size():
				to_cull.append(j)
				if arr[j].contains("-->"):
					end_found = true
				j = j+1
			i = j-1
		elif type !=3:
			if !arr[i].begins_with(keyword) or arr[i].begins_with(keyword + "s"):
				to_cull.append(i)
			else:
				# Used to determine if it's actually one of the entries we're looking for
				var found_something : bool = false
				
				#Checks
				match keyword:
					"string":
						found_something = true
					"Faction":
						if arr[i].contains("owner=\""):
							found_something = true
					"Settlement":
						var j = i+1
						while !found_something and j < arr.size() and !arr[j].begins_with("/" + keyword):
							if(arr[j].begins_with("Town")):
								if(arr[j].contains("is_castle=\"true\"")):
									arr[i] += "<tier=barony>"
								else:
									arr[i] += "<tier=county>"
								found_something = true
							elif(arr[j].begins_with("Village")):
								var bound_to = _get_property(arr[j], "bound")
								bound_to = bound_to.substr(bound_to.find(".")+1)
								arr[i] += "<tier=lordship><bound=" + bound_to + ">"
								found_something = true
							j += 1
				if !found_something:
					to_cull.append(i)
		else:
			if !arr[i].begins_with(" match=\"Settlement") and !arr[i].begins_with(" match=\"Faction") and !arr[i].begins_with(" match=\"string"):
				to_cull.append(i)
		i = i+1
	to_cull.reverse()
	for k in to_cull.size():
		arr.remove_at(to_cull[k])

func _custom_parse_overrides (arr: PackedStringArray):
	var settlements : Dictionary
	var clans : Dictionary
	var localizations : Dictionary
	var ret : Dictionary = {
		"for_test": "",
		"settlements": settlements,
		"clans": clans,
		"localizations": localizations,
		"non-existing": false
	}
	var unusable : int = 0
	for i in arr.size():
		var override = _get_override(arr[i])
		match override["class"]:
			"Settlement":
				if !EncyclopediaManager.settlements.has(override["id"]):
					ret["non-existing"] = true
					unusable += 1
				elif Settlement._get_used_keys().has(override["property"]):
					if override["property"] == "bound":
						override["new_value"] = override["new_value"].substr(override["new_value"].find(".")+1)
					settlements[override["id"]] = override
			"Faction":
				if !EncyclopediaManager.clans.has(override["id"]):
					ret["non-existing"] = true
					unusable += 1
				elif Faction._get_used_keys().has(override["property"]):
					clans[override["id"]] = override
			"string":
				if !EncyclopediaManager.localizations.has(override["id"]):
					ret["non-existing"] = true
					unusable += 1
				else:
					localizations[override["id"]] = override
		ret["for_test"] += " - To the " + override["class"] + ": " + override["id"] + " with new " + override["property"] + "\n"
	ret["for_test"] = "[u]Contains the following " + str(arr.size()) + " overrides, of which usable are " + str(arr.size()-unusable) + ":[/u]\n" + ret["for_test"]
	return ret

func _custom_parse_language(arr : PackedStringArray):
	var data : Dictionary
	var ret : Dictionary = {
		"for_test": "[u]Contains the following " + str(arr.size()) + " localizations:[/u]\n",
		"data": data
	}
	for i in arr.size():
		var key = _get_property(arr[i], "id")
		data[key] = _get_property(arr[i], "text")
		ret["for_test"] += key + "\n"
	return ret

func _custom_parse_clans(arr : PackedStringArray):
	var data : Dictionary
	var ret : Dictionary = {
		"for_test": "[u]Contains the following " + str(arr.size()) + " clans:[/u]\n",
		"data": data
	}
	for i in arr.size():
		var clan : Dictionary
		clan["id"] = _get_property(arr[i], "id")
		clan["name"] = _get_property(arr[i], "name")
		clan["tier"] = _get_property(arr[i], "tier")
		clan["culture"] = _get_property(arr[i], "culture")
		clan["super_faction"] = _get_property(arr[i], "super_faction")
		ret["for_test"] += " - " + EncyclopediaManager._get_name_from_raw(clan["name"]) + "\n"
		data[clan["id"]] = clan
	return ret

func _custom_parse_settlements(arr : PackedStringArray):
	var data : Dictionary
	var ret : Dictionary = {
		"for_test": "[u]Contains the following " + str(arr.size()) + " settlements:[/u]\n",
		"data": data
	}
	for i in arr.size():
		var settlement : Dictionary
		settlement["id"] = _get_property(arr[i], "id")
		settlement["name"] = _get_property(arr[i], "name")
		settlement["posX"] = _get_property(arr[i], "posX") as float
		settlement["posY"] = _get_property(arr[i], "posY") as float
		settlement["culture"] = _get_property(arr[i], "culture").substr(8)
		settlement["text"] = _get_property(arr[i], "text")
		if(arr[i].contains("<tier=barony>")):
			settlement["tier"] = "Barony"
			#Stripping "Faction." from the start
			settlement["owner"] = _get_property(arr[i], "owner").substr(8)
		elif(arr[i].contains("<tier=county>")):
			settlement["tier"] = "County"
			#Stripping "Faction." from the start
			settlement["owner"] = _get_property(arr[i], "owner").substr(8)
		else:
			settlement["tier"] = "Lordship"
			var bound = arr[i].substr(arr[i].find("bound="))
			bound = bound.substr(6, bound.length()-7)
			settlement["bound"] = bound
			
		ret["for_test"] += " - " + EncyclopediaManager._get_name_from_raw(settlement["name"]) + " (" + settlement["tier"]
		if settlement.has("bound"):
			ret["for_test"] += " bound to "
			if data.has(settlement["bound"]):
				ret["for_test"] += EncyclopediaManager._get_name_from_raw(data[settlement["bound"]]["name"])
			else:
				ret["for_test"] += settlement["bound"]
		ret["for_test"] += ")\n"
		data[settlement["id"]] = settlement
	return ret

func _get_property(source: String, name : String, mark : String = "\""):
	if source.contains(name + "=" + mark):
		var loc : int = source.find(name + "=" + mark) + name.length() + 1 + mark.length()
		return source.substr(loc, source.substr(loc).find(mark))
	#CE Tempuner Fix
	elif source.contains(name + "=\""):
		var loc : int = source.find(name + "=\"") + name.length() + 2
		return source.substr(loc, source.substr(loc).find("\""))
	else:
		return "[No " + name + " property found on import]"

func _get_override(source: String):
	var ret : Dictionary
	var raw = _get_property(source, "match")
	ret["class"] = raw.substr(0, raw.find("["))
	ret["id"] = _get_property(source, "@id", "\'")
	var attribute_line : String = source.substr(source.find("<")+1)
	ret["property"] = _get_property(attribute_line, "name", "\'")
	ret["new_value"] = attribute_line.substr(attribute_line.find(">")+1, attribute_line.find("<") - attribute_line.find(">")-1)
	return ret

func _import_with_parser(type : int, full_path : String, label : RichTextLabel, test : bool):
	var error = parser.open(full_path)
	match error:
		OK:
			while parser.read() != ERR_FILE_EOF:
				for i in parser.get_attribute_count():
					print(parser.get_attribute_name(i) + ": " + parser.get_attribute_value(i) + "\n")
					# TODO, full parse is too time consuming for our ends.
		_:
			label.text = unknown_open_error
