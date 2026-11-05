extends Node2D

@onready var jato: AnimatedSprite2D = $Jato

func _ready() -> void:
    visible = false
    jato.visible = false
    jato.animation_finished.connect(_ao_terminar_jato)

func iniciar() -> void:
    jato.stop()
    jato.frame = 0
    visible = true
    jato.visible = true
    jato.play("jato")

func _ao_terminar_jato() -> void:
    jato.visible = false
    visible = false
