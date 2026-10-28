extends Node

const Tokens = preload("res://core/theme/theme_tokens.gd")

func tokens() -> Script:
    return Tokens

func panel_style(fill: Color = Tokens.PANEL, border: Color = Tokens.BORDER, radius: int = Tokens.RADIUS_MEDIUM, border_width: int = 1) -> StyleBoxFlat:
    var box := StyleBoxFlat.new()
    box.bg_color = fill
    box.border_color = border
    box.border_width_left = border_width
    box.border_width_top = border_width
    box.border_width_right = border_width
    box.border_width_bottom = border_width
    box.corner_radius_top_left = radius
    box.corner_radius_top_right = radius
    box.corner_radius_bottom_left = radius
    box.corner_radius_bottom_right = radius
    return box

func button_style(hover: bool = false) -> StyleBoxFlat:
    return panel_style(Tokens.BUTTON_HOVER if hover else Tokens.BUTTON, Tokens.BORDER, Tokens.RADIUS_SMALL, 1)
