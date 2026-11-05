extends Area2D

var tempo: float = 0.0
var posicao_y_original: float = 0.0
var escala_original: Vector2

func _ready() -> void:
    body_entered.connect(_coletar)
    posicao_y_original = $Sprite2D.position.y
    escala_original = $Sprite2D.scale
    $Sprite2D.modulate = Color.WHITE

func _process(delta: float) -> void:
    tempo += delta
    $Sprite2D.position.y = posicao_y_original + sin(tempo * 3.3) * 4.0
    $Sprite2D.rotation = sin(tempo * 2.1) * 0.08
    var pulso := 1.0 + (sin(tempo * 4.0) + 1.0) * 0.055
    $Sprite2D.scale = escala_original * pulso
    # Brilho laranja pulsante sem alterar as cores originais da marca.
    $Sprite2D.modulate = Color(1.0, 0.92 + sin(tempo * 4.0) * 0.06, 0.78 + sin(tempo * 4.0) * 0.10, 1.0)

func _coletar(body: Node2D) -> void:
    if body.is_in_group("jogador") and not body.game_over:
        body.coletar_cruzeiro()
        if get_parent().has_method("item_coletado"):
            get_parent().item_coletado(self)
        queue_free()
