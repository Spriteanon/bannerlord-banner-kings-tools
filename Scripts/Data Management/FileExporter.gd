class_name FileExporter

func _export(full_path : String = OS.get_executable_path().substr(0, OS.get_executable_path().rfind("/")+1)):
	var file = FileAccess.open(full_path+"titles.xml", FileAccess.WRITE)
	file.store_string("<?xml version=\"1.0\" encoding=\"utf-8\"?>\n<base xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\" xmlns:xsd=\"http://www.w3.org/2001/XMLSchema\" type=\"string\">\n	<titles autoGenerate=\"true\">\n")
	for title in EncyclopediaManager.titles.values():
		if title.tier == 4:
			file.store_string("		<kingdom faction=\"" + title.id + "\" contract=\"")
			match title.contract_type:
				Title.Contract_Types.FEUDAL:
					file.store_string("feudal")
				Title.Contract_Types.TRIBAL:
					file.store_string("tribal")
				Title.Contract_Types.IMPERIAL:
					file.store_string("imperial")
				Title.Contract_Types.REPUBLIC:
					file.store_string("republic")
			file.store_string("\" de_Jure=\"" + title._get_owner_hero() + "\">\n")
			for duchy in title.de_jure_vassals:
				file.store_string("			<duchy name=\"" + duchy.title_name + "\" de_Jure=\"" + duchy._get_owner_hero() + "\">\n")
				for county in duchy.de_jure_vassals:
					var baronies_string = ""
					for barony in county.de_jure_vassals:
						if barony.tier == 1:
							baronies_string += "					<barony settlement=\""+barony.capital.data["id"]+"\" deJure=\"" + barony._get_owner_hero() + "\"/>\n"
					if baronies_string != "":
						file.store_string("				<county name=\"" + county.title_name + "\" de_Jure=\"" + county._get_owner_hero() + "\">\n" + baronies_string + "				</county>\n")
					else:
						file.store_string("				<county name=\"" + county.title_name + "\" de_Jure=\"" + county._get_owner_hero() + "\"/>\n")
			file.store_string("		</kingdom>\n")
	file.store_string("	</titles>\n</base>")
