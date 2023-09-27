extends Control

class_name Cartographer

var map_tile = preload("res://Scenes/UI Elements/Map Tile.tscn")

@export var encyclopedia : EncyclopediaManager
@export var map_container : Control

var map : Rect2

var cartographer_tools : Delaunay


func _get_settlements():
	return encyclopedia.settlements.values()

func _calculate_size():
	var minX : float
	var minY : float
	var maxX : float
	var maxY : float
	var settlements = _get_settlements()
	if settlements.size() > 0:
		minX = settlements[0]["posX"]
		maxX = settlements[0]["posX"]
		minY = settlements[0]["posY"]
		maxY = settlements[0]["posY"]
		for i in range(1, settlements.size()):
			if(minX > settlements[i]["posX"]):
				minX = settlements[i]["posX"]
			elif(maxX < settlements[i]["posX"]):
				maxX = settlements[i]["posX"]
				
			if(minY > settlements[i]["posY"]):
				minY = settlements[i]["posY"]
			elif(maxY < settlements[i]["posY"]):
				maxY = settlements[i]["posY"]
	map = Rect2(minX-20, minY-20, maxX-minX+40, maxY-minY+40)
	
func _clean():
	for tile in map_container.get_children():
		tile.queue_free()

func _generate_map():
	_clean()
	_calculate_size()
	cartographer_tools = Delaunay.new(map)
	for settlement in _get_settlements():
		cartographer_tools.add_point(settlement["node"]._get_vector())
	var triangulation = cartographer_tools.triangulate()
	var voronoi = cartographer_tools.make_voronoi(triangulation)
	var rng = RandomNumberGenerator.new()
	rng.seed = hash("I really can't thank bartekd97 enough for creating the Voronoi algorithm")
	for site in voronoi:
		var tile = Polygon2D.new()
		tile.color = Color.from_hsv(rng.randf(), 0.7, 1)
		tile.polygon = site.polygon
		map_container.add_child(tile)
		tile.set_owner(map_container)
	var node_to_save = map_container

	var scene = PackedScene.new()

	scene.pack(node_to_save)

	ResourceSaver.save(scene, "res://Voronoi Debug.tscn")
