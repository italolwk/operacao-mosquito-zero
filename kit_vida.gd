extends Area2D

@export var vida_recuperada: int = 1

func _ready() -> void:
    body_entered.connect(_coletar)
    var animacao: Tween = create_tween().set_loops()
    animacao.tween_property($Sprite2D, "scale", Vector2(0.69, 0.69), 0.55)
    animacao.tween_property($Sprite2D, "scale", Vector2(0.62, 0.62), 0.55)

func _coletar(body: Node2D) -> void:
    if not body.is_in_group("jogador") or body.game_over:
        return
    if body.vida >= body.vida_maxima:
        return
    body.recuperar_vida(vida_recuperada)
    if get_parent().has_method("item_coletado"):
        get_parent().item_coletado(self)
    queue_free()
