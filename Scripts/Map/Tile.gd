extends Polygon2D


class_name Tile

enum Manipulation_Mode {ADD_VASSAL, FREE_TITLE}

static var current_mode = Manipulation_Mode.ADD_VASSAL
static var current_tier
static var selected_title : Title
static var was_dimmed : bool

var settlement : Settlement

var borders : Array

var mouse_inside = false

static var icons : Dictionary = {0:preload("res://Resources/Images/Village.png"), 1:preload("res://Resources/Images/Castle.png"), 2:preload("res://Resources/Images/Town.png")}
static var icon_scales : Dictionary = {0:0.05, 1:0.05, 2:0.08}
static var label_min_zoom : Dictionary = {0:6, 1:3, 2:0}

@export var collider : CollisionPolygon2D
@export var icon : Sprite2D
@export var label_container : PanelContainer
@export var label : Label

func _get_all_neighbours():
	var ret : Array = []
	for border in borders:
		ret.append(border._get_neighbour(self))
	return ret

func _is_part_of_title(title : Title) -> bool:
	return settlement.title._is_part_of_title(title)

func _setup(poly : PackedVector2Array, sett : Settlement):
	polygon = poly
	collider.polygon = poly
	settlement = sett
	icon.texture = icons[settlement.title.tier]
	icon.scale *= icon_scales[settlement.title.tier]
	icon.position = settlement._get_vector()
	label.text = settlement._get_name()
	name = settlement._get_name()

func _color_by_tier():
	if settlement == null:
		return
	match settlement.title.tier:
		0:
			color = Color(0.749, 0.4, 0.251)
		1: 
			color = Color(0.396, 0.541, 0.894)
		2:
			color = Color(0.616, 0.459, 0.875)

func mouse_entered():
	mouse_inside = true

func mouse_exited():
	mouse_inside = false

func _input(event):
	#This is absurdly convoluted, required until https://github.com/godotengine/godot/issues/54529 is handled
	if mouse_inside and event.is_action_pressed("select") and Cartographer.instance.map_container.get_parent().get_parent().get_local_mouse_position().y > 0:
		if current_mode == Manipulation_Mode.ADD_VASSAL and current_tier > 0:
			if selected_title == null and current_tier < 4:
				selected_title = settlement.title._get_liege_at_tier(current_tier)
				if selected_title != null:
					was_dimmed = Cartographer.instance.dim_switch.button_pressed
					Cartographer.instance.dim_switch.button_pressed = true
					Cartographer._color_tiles_by(current_tier+3)
					Cartographer.instance.color_selector.disabled = true
					Cartographer.instance.dim_switch.disabled = true
					Cartographer._highlight_borders(selected_title)
			else:
				if selected_title != settlement.title._get_liege_at_tier(current_tier):
					var potential_liege = settlement.title._get_liege_at_tier(current_tier+1)
					if potential_liege == null:
						return
					potential_liege._add_vassal(selected_title)
				selected_title = null
				Cartographer._set_color_rule(current_tier+2)
				Cartographer.instance.color_selector.disabled = false
				Cartographer.instance.dim_switch.disabled = false
				Cartographer.instance.dim_switch.button_pressed = was_dimmed
				Cartographer._update_map()

func _set_to_zoom(zoom):
	if !Cartographer.show_names or zoom < label_min_zoom[settlement.title.tier]:
		label_container.visible = false
	else:
		label_container.visible = true
		label_container.position = settlement._get_vector() + Vector2(-label.size.x/2, -30.0/7)
		label_container.pivot_offset = Vector2(label.size.x/2, 0)
		label_container.scale = Vector2(1/zoom, -1/zoom)
