extends SceneTree
const GAME=preload("res://scenes/game.tscn")
const GS=preload("res://domain/chess/game_state.gd")
func _initialize()->void:
 var sv:=SubViewport.new();sv.size=Vector2(390,844);sv.render_target_update_mode=SubViewport.UPDATE_ALWAYS;root.add_child(sv)
 var app=root.get_node_or_null("App");if app:app.selected_mode=GS.MODE_2C2;app.temporary_online_bots=false
 var g=GAME.instantiate();sv.add_child(g);await process_frame;await process_frame
 g.game.set_temporary_bot(2, "nora")
 g.game.current_slot = 2
 g.game.bot_prepare_suggestion()
 await process_frame;await process_frame
 var img:=sv.get_texture().get_image();if img:img.save_png("/mnt/data/v50_suggestion_mobile.png")
 quit()
