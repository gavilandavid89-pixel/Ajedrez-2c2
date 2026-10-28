extends RefCounted
class_name RuntimeServices

static func get_autoload(node_name: String) -> Node:
    var loop := Engine.get_main_loop()
    if loop == null or not (loop is SceneTree):
        return null
    var tree := loop as SceneTree
    if tree.root == null or not is_instance_valid(tree.root):
        return null
    return tree.root.get_node_or_null(node_name)

static func change_scene(scene_path: String) -> int:
    var loop := Engine.get_main_loop()
    if loop == null or not (loop is SceneTree):
        return ERR_UNCONFIGURED
    var tree := loop as SceneTree
    if tree.root == null or not is_instance_valid(tree.root):
        return ERR_UNCONFIGURED
    var app := tree.root.get_node_or_null("App")
    var result := OK
    if app != null and app.has_method("change_scene"):
        app.change_scene(scene_path)
    else:
        result = tree.change_scene_to_file(scene_path)
    var supervisor := tree.root.get_node_or_null("SupervisorHub")
    if supervisor != null and result != OK and supervisor.has_method("record_runtime_error"):
        supervisor.record_runtime_error("navigation", "Scene change request failed", {"scene_path": scene_path, "error_code": result})
    # App reports successful navigation after scene_changed + process_frame,
    # when the destination is real and ready for a useful screenshot.
    return result
