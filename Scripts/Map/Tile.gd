extends Polygon2D

class_name Tile

var settlement : Settlement

var neighbours : Array

@export var collider : CollisionPolygon2D

func _setup(poly : PackedVector2Array, sett : Settlement):
	polygon = poly
	collider.polygon = poly
	settlement = sett

func _color_by_tier():
	if settlement == null:
		return
	match EncyclopediaManager.tier_to_num[settlement.data["tier"]]:
		0:
			modulate = Color(0.749, 0.4, 0.251)
		1: 
			modulate = Color(0.396, 0.541, 0.894)
		2:
			modulate = Color(0.616, 0.459, 0.875)
