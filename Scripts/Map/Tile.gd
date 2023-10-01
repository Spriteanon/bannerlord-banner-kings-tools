extends Polygon2D


class_name Tile

var settlement : Settlement

var borders : Array

static var icons : Dictionary = {0:preload("res://Resources/Images/Village.png"), 1:preload("res://Resources/Images/Castle.png"), 2:preload("res://Resources/Images/Town.png")}
static var icon_scales : Dictionary = {0:0.05, 1:0.05, 2:0.08}
static var label_min_zoom : Dictionary = {0:6, 1:3, 2:0}

@export var collider : CollisionPolygon2D
@export var icon : Sprite2D
@export var label_container : PanelContainer
@export var label : Label

func _get_all_neighbours():
	var ret : Array
	for border in borders:
		ret.append(border._get_neighbour(self))
	return ret

func _setup(poly : PackedVector2Array, sett : Settlement):
	polygon = poly
	#collider.polygon = poly
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

func _on_area_2d_mouse_entered():
	print(settlement.data["id"])

func _set_to_zoom(zoom):
	if !Cartographer.show_names or zoom < label_min_zoom[settlement.title.tier]:
		label_container.visible = false
	else:
		label_container.visible = true
		label_container.position = settlement._get_vector() + Vector2(-label.size.x/2, -30/7)
		label_container.pivot_offset = Vector2(label.size.x/2, 0)
		label_container.scale = Vector2(1/zoom, -1/zoom)
