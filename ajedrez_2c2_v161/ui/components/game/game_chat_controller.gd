extends RefCounted
class_name GameChatController

signal close_requested
signal message_submitted(text: String)

var panel: Control
var messages: RichTextLabel
var input: LineEdit

func attach(root: Control) -> void:
    panel = root
    messages = root.get_node_or_null("Messages") as RichTextLabel
    input = root.get_node_or_null("Input") as LineEdit
    var close_button := root.get_node_or_null("Close") as Button
    if close_button != null and not close_button.pressed.is_connected(_on_close):
        close_button.pressed.connect(_on_close)
    if input != null and not input.text_submitted.is_connected(_on_submit):
        input.text_submitted.connect(_on_submit)

func open() -> void:
    if panel != null:
        panel.visible = true
        if input != null:
            input.grab_focus.call_deferred()

func close() -> void:
    if panel != null:
        panel.visible = false

func toggle() -> void:
    if panel == null:
        return
    if panel.visible:
        close()
    else:
        open()

func set_messages(text: String) -> void:
    if messages != null:
        messages.text = text

func clear_input() -> void:
    if input != null:
        input.text = ""

func _on_submit(text: String) -> void:
    var cleaned := text.strip_edges()
    if cleaned.is_empty():
        return
    message_submitted.emit(cleaned)

func _on_close() -> void:
    close_requested.emit()
    close()
