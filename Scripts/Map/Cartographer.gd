extends Control

class_name Cartographer


var map_tile = preload("res://Scenes/UI Elements/Map Tile.tscn")
var border_prefab = preload("res://Scenes/UI Elements/Border.tscn")

var max_zoom = 10
var min_zoom = 1
static var show_names = true

var panning = false
var mouse_pos_last = Vector2(-1, -1)

@export var encyclopedia : EncyclopediaManager
@export var map_container : Control
@export var color_selector : OptionButton
@export var dim_switch : CheckButton

static var instance

static var rng = RandomNumberGenerator.new()

var map : Rect2

var cartographer_tools : Delaunay

static var tiles : Array
static var borders : Array

static var previous_rule = 2

func _ready():
	instance = self

func _get_settlements():
	return encyclopedia.settlements.values()

static func _set_color_rule(rule : int = previous_rule):
	previous_rule = rule
	instance.color_selector.selected = rule
	Tile.current_tier = rule - 2
	_color_tiles_by(rule)

@warning_ignore("unused_parameter") # Variable only present for maximum compatibility with signal
static func _change_dim(dim : bool ):
	_color_tiles_by()

static func _color_tiles_by(rule : int = previous_rule):
	match rule:
		0:
			for tile in tiles:
				tile.color = Color.from_hsv(rng.randf(), 0.7, 1)
		1:
			for tile in tiles:
				tile._color_by_tier()
		2, 3, 4, 5, 6, 7:
			for tile in tiles:
				if !instance.dim_switch.button_pressed or tile.settlement.title._get_liege_at_tier(rule-2) != null:
					tile.color = tile.settlement.title._get_color(rule - 2)
				else:
					tile.color = Color.DIM_GRAY
		8:
			var culture_steps : float = 1.0 / EncyclopediaManager.settlement_cultures.size()
			for tile in tiles:
				var culture_loc = EncyclopediaManager.settlement_cultures.find(tile.settlement.data["culture"])
				tile.color = Color.from_hsv(culture_loc * culture_steps, 0.7, 1)
		9:
			for tile in tiles:
				match tile.settlement.title._get_contract_type():
					0:
						tile.color = Color8(91, 133, 207)
					1:
						tile.color = Color8(92, 31, 23)
					2:
						tile.color = Color8(143, 12, 125)
					3:
						tile.color = Color8(250, 0, 0)
					_:
						tile.color = Color8(169, 169, 169)

func _calculate_size():
	var settlements = _get_settlements()
	
	var array : PackedVector2Array = []
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

static func _update_map():
	for border in borders:
		border._set_width_by_relations()
		border._highlight()
	_color_tiles_by()

static func _highlight_borders(title : Title = null):
	for border in borders:
		border._highlight(title)

func _generate_map():
	if encyclopedia.settlements.is_empty():
		return
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
				if EncyclopediaManager.tier_to_num[settlements_to_pair[j]["tier"]] == 2:
					var liege = settlements_to_pair[j]["node"].title.de_jure_liege
					if liege != null and liege.color == Color.BLACK:
						liege.color = settlements_to_pair[j]["node"].title.color
				settlements_to_pair.remove_at(j)
				tiles.append(tile)
				tile._set_to_zoom(map_container.scale.x)
				_check_for_borders(voronoi, i, tile)
			j += 1
		if !paired:
			print("Failed to pair Voronoi Site " + str(i))
		i += 1
	for border in borders:
		border._set_width_by_relations()
		border._highlight()
		map_container.add_child(border)
		border.set_owner(map_container)
	Cartographer._set_color_rule()

func _input(event):
	if visible and !color_selector.disabled:
		if event.is_action_pressed("iterate_sorting_plus"):
			if previous_rule == color_selector.item_count -1:
				color_selector.selected = 0
			else:
				color_selector.selected += 1
			Cartographer._set_color_rule(color_selector.selected)
		elif event.is_action_pressed("iterate_sorting_minus"):
			if previous_rule == 0:
				color_selector.selected = color_selector.item_count -1
			else:
				color_selector.selected -= 1
			Cartographer._set_color_rule(color_selector.selected)


func _gui_input(event):
	if map_container.get_parent().get_local_mouse_position().y < 0:
		return
	if event.is_action_pressed("zoom_in"):
		zoom(0.05)
	elif event.is_action_pressed("zoom_out"):
		zoom(-0.05)
	elif event.is_action("pan_view"):
		if event.is_pressed():
			panning = true
			mouse_pos_last = map_container.get_local_mouse_position()
		else:
			panning = false

@warning_ignore("unused_parameter") # Delta unneeded
func _process(delta):
	if panning:
		map_container.position -= mouse_pos_last - map_container.get_local_mouse_position()

func zoom(amount):
	var prev_zoom = map_container.scale.x
	map_container.scale *= 1 + amount
	if map_container.scale.x < min_zoom:
			map_container.scale *= min_zoom/map_container.scale.x
	elif map_container.scale.x > max_zoom:
			map_container.scale *= max_zoom/map_container.scale.x
	map_container.position += map_container.get_local_mouse_position()*(prev_zoom - map_container.scale.x)
	for tile in tiles:
		tile._set_to_zoom(map_container.scale.x)


func _show_names(button_pressed):
	show_names = button_pressed
	for tile in tiles:
		tile._set_to_zoom(map_container.scale.x)
