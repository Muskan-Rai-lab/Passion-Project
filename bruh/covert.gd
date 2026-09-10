@tool
extends EditorScript

func _run():
	var selected_nodes = get_editor_interface().get_selection().get_selected_nodes()
	var save_dir = "res://saved_bodies/"
	var scene_root = get_editor_interface().get_edited_scene_root()

	for node in selected_nodes:
		if node is StaticBody3D:
			var scene_path = find_scene_path(node.name, save_dir)
			if scene_path == "":
				print("No matching scene found for: ", node.name)
				continue

			var packed_scene = load(scene_path)
			var instance = packed_scene.instantiate()

			var parent = node.get_parent()
			var global_transform = node.global_transform
			var original_name = node.name

			parent.remove_child(node)
			node.queue_free()

			parent.add_child(instance)
			instance.owner = scene_root
			instance.name = original_name
			instance.global_transform = global_transform

			print("Replaced: ", original_name, " with ", scene_path)


func find_scene_path(node_name: String, save_dir: String) -> String:
	var regex = RegEx.new()
	regex.compile("\\d+$")
	var base_name = regex.sub(node_name, "", true)

	var base_path = save_dir + base_name + ".tscn"
	if ResourceLoader.exists(base_path):
		return base_path

	var exact_path = save_dir + node_name + ".tscn"
	if ResourceLoader.exists(exact_path):
		return exact_path

	return ""
