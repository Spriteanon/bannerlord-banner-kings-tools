extends Control

class_name Cartographer


var map_tile = preload("res://Scenes/UI Elements/Map Tile.tscn")
var border_prefab = preload("res://Scenes/UI Elements/Border.tscn")

@export var encyclopedia : EncyclopediaManager
@export var map_container : Control

var rng = RandomNumberGenerator.new()

var map : Rect2

var cartographer_tools : Delaunay

var tiles : Array
var borders : Array

var previous_rule = 2

func _get_settlements():
	return encyclopedia.settlements.values()

func _color_tiles_by(rule : int = previous_rule):
	previous_rule = rule
	match rule:
		0:
			for tile in tiles:
				tile.color = Color.from_hsv(rng.randf(), 0.7, 1)
		1:
			for tile in tiles:
				tile._color_by_tier()
		2, 3, 4, 5, 6, 7:
			#Temp block
			if rule > 4:
				return
			for tile in tiles:
				tile.color = tile.settlement.title._get_color(rule - 2)

func _calculate_size():
	var settlements = _get_settlements()
	
	var array : PackedVector2Array
	for settlement in settlements:
		array.append(settlement["node"]._get_vector())
	
	if settlements.size() > 0:
		map.position = array[0]
		for i in range(1, settlements.size()):
			map.position.x = min(array[i].x, map.position.x)
			map.position.y = min(array[i].y, map.position.y)
			map.size.x = max(array[i].x, map.size.x)
			map.size.y = max(array[i].y, map.size.y)
	
func _clean():
	for tile in map_container.get_children():
		tile.queue_free()
	tiles.clear()
	borders.clear()

func _check_for_borders(voronoi : Array, i : int, tile : Tile):
	for neighbour in voronoi[i].neighbours:
		var other
		if neighbour.this == voronoi[i]:
			other = neighbour.other
		else:
			other = neighbour.this
		var other_loc = voronoi.rfind(other, i)
		if other_loc != -1:
			var new_border = border_prefab.instantiate()
			new_border.neighbour_a = tile
			new_border.neighbour_b = tiles[other_loc]
			new_border.add_point(neighbour.a)
			new_border.add_point(neighbour.b)
			borders.append(new_border)

func _generate_map():
	_clean()
	_calculate_size()
	cartographer_tools = Delaunay.new()
	for settlement in _get_settlements():
		cartographer_tools.add_point(settlement["node"]._get_vector())
	var triangulation = cartographer_tools.triangulate()
	var voronoi = cartographer_tools.make_voronoi(triangulation)
	rng.seed = hash("I really can't thank bartekd97 enough for creating the Voronoi algorithm")
	var settlements_to_pair = _get_settlements()
	var i : int = 0
	while i < voronoi.size():
		var tile = map_tile.instantiate()
		tile.color = Color.from_hsv(rng.randf(), 0.7, 1)
		var j : int = 0
		var paired : bool = false
		while !paired and j < settlements_to_pair.size():
			if settlements_to_pair[j]["node"]._get_vector() == voronoi[i].center:
				paired = true
				tile._setup(voronoi[i].polygon, settlements_to_pair[j]["node"])
				map_container.add_child(tile)
				tile.set_owner(map_container)
				settlements_to_pair[j]["node"].tile = tile
				settlements_to_pair[j]["node"].title.color = tile.color
				settlements_to_pair.remove_at(j)
				tiles.append(tile)
				_check_for_borders(voronoi, i, tile)
			j += 1
		if !paired:
			print("Failed to pair Voronoi Site " + str(i))
		i += 1
	for border in borders:
		border._set_width_by_relations()
		map_container.add_child(border)
		border.set_owner(map_container)
	_color_tiles_by()
