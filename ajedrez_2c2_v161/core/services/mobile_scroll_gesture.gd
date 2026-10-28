extends Node

## Global mobile gesture arbitration for ScrollContainers.
## A touch that becomes a drag is routed to the deepest scrollable viewport
## under the finger, even when the gesture began over a Button or a row.
## A completed drag is marked handled so controls do not activate on release.

const DRAG_THRESHOLD := 9.0
const AXIS_LOCK_RATIO := 1.15

var _touch_index := -1
var _start_position := Vector2.ZERO
var _last_position := Vector2.ZERO
var _candidates: Array[ScrollContainer] = []
var _dragging := false
var _axis := 0 # 1 vertical, 2 horizontal
var _active_scroll: ScrollContainer

func _input(event: InputEvent) -> void:
    if event is InputEventScreenTouch:
        var touch := event as InputEventScreenTouch
        if touch.pressed:
            _begin_touch(touch.position, touch.index)
        elif touch.index == _touch_index:
            if _dragging:
                get_viewport().set_input_as_handled()
            _clear_touch()
        return

    if event is InputEventScreenDrag:
        var drag := event as InputEventScreenDrag
        if _touch_index < 0 or drag.index != _touch_index:
            return
        var total := drag.position - _start_position
        if not _dragging and total.length() >= DRAG_THRESHOLD:
            _dragging = true
            _axis = _choose_axis(total)
            _active_scroll = _choose_scroll_for_axis(_axis)
            if _active_scroll == null:
                var fallback_axis := 2 if _axis == 1 else 1
                _active_scroll = _choose_scroll_for_axis(fallback_axis)
                if _active_scroll != null:
                    _axis = fallback_axis
        if _dragging:
            if _active_scroll != null and is_instance_valid(_active_scroll):
                var delta := drag.position - _last_position
                if _axis == 1:
                    _active_scroll.scroll_vertical = _clamp_scroll(_active_scroll, false, _active_scroll.scroll_vertical - roundi(delta.y))
                else:
                    _active_scroll.scroll_horizontal = _clamp_scroll(_active_scroll, true, _active_scroll.scroll_horizontal - roundi(delta.x))
            get_viewport().set_input_as_handled()
        _last_position = drag.position

func _begin_touch(position: Vector2, index: int) -> void:
    _clear_touch()
    _touch_index = index
    _start_position = position
    _last_position = position
    _collect_scrolls(get_tree().root, position, _candidates)
    _candidates.sort_custom(func(a: ScrollContainer, b: ScrollContainer) -> bool:
        return _tree_depth(a) > _tree_depth(b)
    )

func _collect_scrolls(node: Node, position: Vector2, result: Array[ScrollContainer]) -> void:
    if node is ScrollContainer:
        var scroll := node as ScrollContainer
        if scroll.is_visible_in_tree() and scroll.get_global_rect().has_point(position):
            var vertical_overflow := scroll.vertical_scroll_mode != ScrollContainer.SCROLL_MODE_DISABLED and scroll.get_v_scroll_bar().max_value > scroll.get_v_scroll_bar().page + 1.0
            var horizontal_overflow := scroll.horizontal_scroll_mode != ScrollContainer.SCROLL_MODE_DISABLED and scroll.get_h_scroll_bar().max_value > scroll.get_h_scroll_bar().page + 1.0
            if vertical_overflow or horizontal_overflow:
                result.append(scroll)
    for child in node.get_children():
        _collect_scrolls(child, position, result)

func _choose_axis(total: Vector2) -> int:
    if absf(total.y) >= absf(total.x) * AXIS_LOCK_RATIO:
        return 1
    if absf(total.x) >= absf(total.y) * AXIS_LOCK_RATIO:
        return 2
    # For diagonal gestures prefer vertical scrolling when available; otherwise
    # use the horizontal scroller. This feels more natural in mobile lists.
    if _has_scroll_axis(1):
        return 1
    return 2

func _has_scroll_axis(axis: int) -> bool:
    for candidate in _candidates:
        if not is_instance_valid(candidate):
            continue
        if axis == 1 and candidate.vertical_scroll_mode != ScrollContainer.SCROLL_MODE_DISABLED and candidate.get_v_scroll_bar().max_value > candidate.get_v_scroll_bar().page + 1.0:
            return true
        if axis == 2 and candidate.horizontal_scroll_mode != ScrollContainer.SCROLL_MODE_DISABLED and candidate.get_h_scroll_bar().max_value > candidate.get_h_scroll_bar().page + 1.0:
            return true
    return false

func _choose_scroll_for_axis(axis: int) -> ScrollContainer:
    for candidate in _candidates:
        if not is_instance_valid(candidate) or not candidate.is_visible_in_tree():
            continue
        if axis == 1:
            if candidate.vertical_scroll_mode != ScrollContainer.SCROLL_MODE_DISABLED and candidate.get_v_scroll_bar().max_value > candidate.get_v_scroll_bar().page + 1.0:
                return candidate
        elif candidate.horizontal_scroll_mode != ScrollContainer.SCROLL_MODE_DISABLED and candidate.get_h_scroll_bar().max_value > candidate.get_h_scroll_bar().page + 1.0:
            return candidate
    return null

func _clamp_scroll(scroll: ScrollContainer, horizontal: bool, value: int) -> int:
    var bar: Range = scroll.get_h_scroll_bar() if horizontal else scroll.get_v_scroll_bar()
    return clampi(value, 0, maxi(0, int(ceil(bar.max_value - bar.page))))

func _tree_depth(node: Node) -> int:
    var depth := 0
    var current: Node = node
    while current != null:
        depth += 1
        current = current.get_parent()
    return depth

func _clear_touch() -> void:
    _touch_index = -1
    _candidates.clear()
    _active_scroll = null
    _dragging = false
    _axis = 0
