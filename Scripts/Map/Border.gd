extends Line2D

class_name Border

var neighbour_a : Tile
var neighbour_b : Tile
var border_a : Vector2
var border_b : Vector2

func _get_neighbour(myself : Tile):
	if myself == neighbour_a:
		return neighbour_b
	return neighbour_a

func _set_width_by_relations():
	var rel = float(neighbour_a.settlement.title._get_relationship(neighbour_b.settlement.title))
	width = rel / 3
