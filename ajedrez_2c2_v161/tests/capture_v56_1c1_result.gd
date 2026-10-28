extends SceneTree
const GAME=preload("res://scenes/game.tscn")
const GS=preload("res://domain/chess/game_state.gd")
func _initialize()->void:
    var sv:=SubViewport.new()
    sv.size=Vector2(360,640)
    sv.render_target_update_mode=SubViewport.UPDATE_ALWAYS
    sv.disable_3d=true
    root.add_child(sv)
    var app=root.get_node_or_null("App")
    if app:
        app.selected_mode=GS.MODE_1C1
    var g=GAME.instantiate()
    sv.add_child(g)
    await process_frame
    await process_frame
    g.game.reset_match(GS.MODE_1C1,10)
    g.game.board = [
        ["rey_negro", "", "", "", "", "", "", ""],
        ["", "dama_blanca", "", "", "", "", "", ""],
        ["", "", "rey_blanca", "", "", "", "", ""],
        ["", "", "", "", "", "", "", ""],
        ["", "", "", "", "", "", "", ""],
        ["", "", "", "", "", "", "", ""],
        ["", "", "", "", "", "", "", ""],
        ["", "", "", "", "", "", "", ""],
    ]
    g.game.finish(GS.TEAM_WHITE,"Jaque mate")
    await process_frame
    await process_frame
    await create_timer(0.5).timeout
    var img:=sv.get_texture().get_image()
    if img:
        img.save_png("/mnt/data/v56_1c1_result_360x640.png")
    sv.queue_free()
    quit()
