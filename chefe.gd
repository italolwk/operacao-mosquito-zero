extends Area2D

signal vida_alterada(atual: int, maxima: int)
signal derrotado

const VIDA_MAXIMA: int = 30
var vida: int = VIDA_MAXIMA
var tempo: float = 0.0
var cooldown_contato: float = 0.0
var morto: bool = false
var alvo: Node2D
var posicao_inicial: Vector2
var piscar: float = 0.0
var direcao_voo: float = 1.0
var animacao_direcao: StringName = &"voar_frente"

@onready var visual: AnimatedSprite2D = $Visual
@onready var hitbox: CollisionShape2D = $CollisionShape2D

func _ready() -> void:
    add_to_group("mosquitos")
    add_to_group("chefe_final")
    alvo = get_tree().get_first_node_in_group("jogador") as Node2D
    posicao_inicial = global_position
    body_entered.connect(_ao_tocar_jogador)
    vida_alterada.emit(vida, VIDA_MAXIMA)

    visual.play(animacao_direcao)
    visual.speed_scale = 1.0

    # Entrada do chefe preservada.
    scale = Vector2(0.72, 0.72)
    modulate = Color(1.25, 1.15, 1.15, 1.0)
    var entrada := create_tween()
    entrada.set_parallel(true)
    entrada.tween_property(self, "scale", Vector2.ONE, 0.55).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
    entrada.tween_property(self, "modulate", Color.WHITE, 0.7)

func _process(delta: float) -> void:
    if morto:
        return

    tempo += delta
    cooldown_contato = maxf(0.0, cooldown_contato - delta)
    piscar = maxf(0.0, piscar - delta * 4.5)

    if not is_instance_valid(alvo) or alvo.get("game_over") == true:
        return

    # Mantém a mesma trajetória orbital e velocidade de deslocamento do chefe anterior.
    var raio_x: float = 175.0 + sin(tempo * 0.75) * 28.0
    var raio_y: float = 88.0 + cos(tempo * 1.1) * 18.0
    var centro_orbita: Vector2 = alvo.global_position + Vector2(
        cos(tempo * 0.78) * raio_x,
        -105.0 + sin(tempo * 1.55) * raio_y
    )

    var direcao_movimento: Vector2 = global_position.direction_to(centro_orbita)
    _atualizar_animacao_direcional(direcao_movimento)

    var fator: float = 1.0 if vida > VIDA_MAXIMA / 3 else 1.18
    global_position = global_position.move_toward(centro_orbita, 150.0 * fator * delta)
    direcao_voo = signf(centro_orbita.x - global_position.x) if absf(centro_orbita.x - global_position.x) > 2.0 else direcao_voo

    # Oscilação vertical discreta para dar sensação de voo.
    visual.position.y = -2.0 + sin(tempo * 5.0) * 2.5
    visual.speed_scale = 1.0 if vida > VIDA_MAXIMA / 3 else 1.12

func _atualizar_animacao_direcional(direcao: Vector2) -> void:
    if morto or direcao.length_squared() < 0.01:
        return

    var nova_animacao: StringName = animacao_direcao
    var lateral: bool = absf(direcao.x) > absf(direcao.y) * 1.08

    if lateral:
        nova_animacao = &"voar_direita" if direcao.x > 0.0 else &"voar_esquerda"
        # A cápsula acompanha o eixo comprido do corpo quando visto de lado.
        hitbox.rotation = PI * 0.5
    else:
        nova_animacao = &"voar_frente" if direcao.y > 0.0 else &"voar_costas"
        hitbox.rotation = 0.0

    if nova_animacao != animacao_direcao:
        animacao_direcao = nova_animacao
        visual.play(animacao_direcao)

func receber_spray(dano: int) -> bool:
    if morto:
        return false

    vida = maxi(0, vida - dano)
    OMZAudio.play_sfx("impacto", -4.0)
    piscar = 1.0
    vida_alterada.emit(vida, VIDA_MAXIMA)

    visual.modulate = Color("#ff7777")
    var impacto := create_tween()
    impacto.tween_property(visual, "modulate", Color.WHITE, 0.20)

    if vida <= 0:
        morrer()
        return true
    return false

func morrer() -> void:
    if morto:
        return

    morto = true
    OMZAudio.play_sfx("mosquito_derrotado", -1.0)
    collision_layer = 0
    collision_mask = 0
    monitoring = false
    monitorable = false
    hitbox.set_deferred("disabled", true)

    var tween := create_tween()
    tween.tween_property(self, "rotation", TAU * 1.4, 0.85)
    tween.parallel().tween_property(self, "scale", Vector2(1.65, 0.18), 0.85).set_trans(Tween.TRANS_BACK)
    tween.parallel().tween_property(self, "modulate", Color(1.0, 0.65, 0.35, 0.0), 0.85)
    await tween.finished
    derrotado.emit()
    queue_free()

func _ao_tocar_jogador(body: Node2D) -> void:
    if not morto and cooldown_contato <= 0.0 and body.is_in_group("jogador"):
        cooldown_contato = 1.1
        if body.has_method("sofrer_dano"):
            body.sofrer_dano(1)
