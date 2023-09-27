class_name Toolbox

static var sort_by_name : Callable = func (a, b):
	return a.name.naturalnocasecmp_to(b.name) < 0

#WIP
static func _sort_children_of_node(node : Node, method : Callable = sort_by_name):
	var sorted_children = node.get_children()
	sorted_children.sort_custom(method)
	for i in sorted_children.size():
		node.move_child(sorted_children[i],i)
