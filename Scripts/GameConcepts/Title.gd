class_name Title

var id : String

var tier : int

var de_jure_vassals : Array

var de_jure_owner : String = ""

var de_jure_liege : Title

var color : Color

#For now only exists in this editor
var capital : Settlement

func _get_color(needed_tier : int):
	if needed_tier > tier and de_jure_liege != null:
		return de_jure_liege._get_color(needed_tier)
	return color

func _get_owner():
	if de_jure_owner != "":
		return de_jure_owner
	else:
		return de_jure_liege._get_owner()

# -1 = Same Title , 0 = Same Barony, 2 = Same County, 3 = Same Duchy,
#  4 = Same Kingdom, 5 = Same Empire, 6 = Different Nations
func _get_relationship(other : Title) -> int:
	var ret = _check_relationship_down(other)
	if ret != 6:
		return ret
	if de_jure_liege != null:
		return _check_relationship_up(self, other)
	return 6
	
func _check_relationship_up(previous : Title, other : Title) -> int:
	if other == self:
		if previous.tier == 0:
			return 0
		return tier
	for vassal in de_jure_vassals:
		if vassal != previous:
			var ret = vassal._check_relationship_down(other)
			if ret != 6:
				return tier
	if de_jure_liege != null:
		return de_jure_liege._check_relationship_up(self, other)
	return 6

func _check_relationship_down(other : Title, depth : int = -1) -> int:
	if other == self:
		return depth + other.tier
	for vassal in de_jure_vassals:
		var ret = vassal._check_relationship_down(other, depth+1)
		if ret != 6:
			return ret
	return 6
