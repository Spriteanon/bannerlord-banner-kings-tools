extends Line2D

class_name Border

var neighbour_a : Tile
var neighbour_b : Tile
var border_a : Vector2
var border_b : Vector2

func _highlight(title : Title = null):
	if title != null and (neighbour_a._is_part_of_title(title) or neighbour_b._is_part_of_title(title)) and (!neighbour_a._is_part_of_title(title) or !neighbour_b._is_part_of_title(title)):
		default_color = Color.WHITE
		z_index = 4
	else:
		if neighbour_a.settlement.title._get_relationship(neighbour_b.settlement.title) == 6:
			default_color = Color.BLACK
			z_index = 3
		else:
			default_color = Color(0.25,0.25,0.25)
			z_index = 1

func _get_neighbour(myself : Tile):
	if myself == neighbour_a:
		return neighbour_b
	return neighbour_a

func _set_width_by_relations():
	var rel = float(neighbour_a.settlement.title._get_relationship(neighbour_b.settlement.title))
	width = rel / 3.5
