extends SceneTree
const DetailScene = preload("res://scenes/club_detail_screen.tscn")
const MembersScene = preload("res://scenes/club_members_screen.tscn")
func _initialize() -> void:
 var clubs = root.get_node_or_null("ClubsService")
 print("clubs", clubs, "active", clubs.active_club_id if clubs else "none", "sel", clubs.get_selected_club() if clubs else {})
 if clubs:
  print("join c1", clubs.join_club("c1"), "active", clubs.active_club_id, "sel", clubs.get_selected_club())
 var detail=DetailScene.instantiate(); root.add_child(detail)
 await process_frame; await process_frame; await process_frame
 print("detail valid", detail.is_inside_tree(), "children", detail.get_tree_string())
 print("members", detail.find_child("MembersLink", true, false))
 var members=MembersScene.instantiate(); root.add_child(members)
 await process_frame; await process_frame; await process_frame
 print("members valid", members.is_inside_tree(), "children", members.get_tree_string())
 print("scroll", members.find_child("MembersScroll", true, false))
 quit()
