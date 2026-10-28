extends Control
class_name GameChatPanel

signal message_submitted(text: String)
signal close_requested

var controller := GameChatController.new()

func _ready() -> void:
    controller.attach(self)
    controller.message_submitted.connect(_forward_message)
    controller.close_requested.connect(_forward_close)

func open_chat() -> void:
    controller.open()

func close_chat() -> void:
    controller.close()

func toggle_chat() -> void:
    controller.toggle()

func set_messages(text: String) -> void:
    controller.set_messages(text)

func clear_input() -> void:
    controller.clear_input()

func _forward_message(text: String) -> void:
    message_submitted.emit(text)

func _forward_close() -> void:
    close_requested.emit()
