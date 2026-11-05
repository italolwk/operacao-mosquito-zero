extends Control

signal fechar_pausa

func _unhandled_input(event: InputEvent) -> void:
    if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE:
        fechar_pausa.emit()
        get_viewport().set_input_as_handled()
