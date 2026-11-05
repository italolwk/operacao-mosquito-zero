extends Area2D

const VELOCIDADE: float = 108.0
var tempo: float = 0.0
var offset_alvo: Vector2 = Vector2.ZERO
var velocidade_local: float = 108.0
var vida_maxima: int = 1
var vida: int = 1
var atingido: bool = false
var morto: bool = false
var animacao_direcao: StringName = &"voar_frente"

func configurar_onda(numero_onda: int) -> void:
    vida_maxima = 2 if numero_onda >= 5 else 1
    vida = vida_maxima

func _ready() -> void:
    add_to_group("mosquitos")
    body_entered.connect(_on_body_entered)
    offset_alvo = Vector2(randf_range(-36.0, 36.0), randf_range(-34.0, 34.0))
    velocidade_local = VELOCIDADE * randf_range(0.85, 1.20)
    $Visual.play(animacao_direcao)

func _process(delta: float) -> void:
    if morto:
        return

    tempo += delta
    var jogador: Node2D = get_tree().get_first_node_in_group("jogador")
    if jogador == null or jogador.game_over:
        return

    var destino: Vector2 = jogador.global_position + offset_alvo
    var direcao: Vector2 = global_position.direction_to(destino)
    var separacao: Vector2 = Vector2.ZERO
    for outro in get_tree().get_nodes_in_group("mosquitos"):
        if outro == self or not is_instance_valid(outro):
            continue
        if outro.get("morto") == true:
            continue
        var distancia: float = global_position.distance_to(outro.global_position)
        if distancia < 43.0 and distancia > 0.0:
            separacao += outro.global_position.direction_to(global_position) * ((43.0 - distancia) / 43.0)

    direcao = (direcao + separacao * 1.8 + Vector2(-direcao.y, direcao.x) * sin(tempo * 4.1) * 0.11).normalized()
    _atualizar_animacao_direcional(direcao)

    # Mantém a velocidade e a lentidão individual já existentes.
    var proporcao: float = float(vida) / float(vida_maxima)
    var multiplicador: float = clampf(0.62 + proporcao * 0.38, 0.62, 1.0)
    $Visual.speed_scale = clampf(0.70 + proporcao * 0.30, 0.70, 1.0)
    global_position += direcao * velocidade_local * multiplicador * delta
    rotation = clampf(direcao.x * 0.08, -0.10, 0.10)

func _atualizar_animacao_direcional(direcao: Vector2) -> void:
    if morto or direcao.length_squared() < 0.01:
        return

    var nova_animacao: StringName = animacao_direcao
    if absf(direcao.x) > absf(direcao.y) * 1.08:
        nova_animacao = &"voar_direita" if direcao.x > 0.0 else &"voar_esquerda"
    else:
        nova_animacao = &"voar_frente" if direcao.y > 0.0 else &"voar_costas"

    if nova_animacao != animacao_direcao:
        animacao_direcao = nova_animacao
        $Visual.play(animacao_direcao)

func receber_spray(dano: int) -> bool:
    if morto or not is_inside_tree():
        return false

    vida = maxi(0, vida - dano)
    if vida > 0:
        OMZAudio.play_sfx("impacto", -3.0)
        $Visual.modulate = Color(1.0, 0.45, 0.38, 1.0)
        var impacto := create_tween()
        impacto.tween_property($Visual, "modulate", Color.WHITE, 0.18)
        return false

    _iniciar_morte()
    return true

func _iniciar_morte() -> void:
    if morto:
        return

    morto = true
    OMZAudio.play_sfx("mosquito_derrotado", -3.0)
    collision_layer = 0
    collision_mask = 0
    set_deferred("monitoring", false)
    set_deferred("monitorable", false)

    if has_node("CollisionShape2D"):
        $CollisionShape2D.set_deferred("disabled", true)

    _particulas_morte()
    $Visual.stop()

    # Pequeno "pop" de impacto seguido de giro, encolhimento e desaparecimento.
    var escala_original: Vector2 = $Visual.scale
    var rotacao_final: float = $Visual.rotation + TAU * 1.15
    var morte := create_tween()
    morte.tween_property($Visual, "scale", escala_original * 1.24, 0.10).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
    morte.parallel().tween_property($Visual, "modulate", Color("#fff2b0"), 0.10)
    morte.tween_property($Visual, "rotation", rotacao_final, 0.38).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
    morte.parallel().tween_property($Visual, "scale", Vector2(0.015, 0.015), 0.38).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
    morte.parallel().tween_property($Visual, "position", Vector2(0, -17), 0.38).set_trans(Tween.TRANS_SINE)
    morte.parallel().tween_property($Visual, "modulate:a", 0.0, 0.38)
    morte.tween_callback(queue_free)

func _particulas_morte() -> void:
    var particulas := CPUParticles2D.new()
    particulas.name = "ParticulasMorteMosquito"
    particulas.amount = 16
    particulas.one_shot = true
    particulas.explosiveness = 1.0
    particulas.lifetime = 0.48
    particulas.direction = Vector2.UP
    particulas.spread = 180.0
    particulas.initial_velocity_min = 35.0
    particulas.initial_velocity_max = 90.0
    particulas.gravity = Vector2(0.0, 65.0)
    particulas.scale_amount_min = 0.55
    particulas.scale_amount_max = 1.15
    particulas.color = Color("#ffe78b")
    get_parent().add_child(particulas)
    particulas.global_position = global_position
    particulas.emitting = true

    var brilho := CPUParticles2D.new()
    brilho.name = "BrilhoMorteMosquito"
    brilho.amount = 8
    brilho.one_shot = true
    brilho.explosiveness = 1.0
    brilho.lifetime = 0.34
    brilho.direction = Vector2.UP
    brilho.spread = 180.0
    brilho.initial_velocity_min = 18.0
    brilho.initial_velocity_max = 55.0
    brilho.gravity = Vector2(0.0, 30.0)
    brilho.scale_amount_min = 0.35
    brilho.scale_amount_max = 0.75
    brilho.color = Color("#b9f5e7")
    get_parent().add_child(brilho)
    brilho.global_position = global_position
    brilho.emitting = true

    get_tree().create_timer(0.9).timeout.connect(func():
        if is_instance_valid(particulas):
            particulas.queue_free()
        if is_instance_valid(brilho):
            brilho.queue_free()
    )

func _on_body_entered(body: Node2D) -> void:
    if morto:
        return
    if body.is_in_group("jogador") and body.has_method("sofrer_dano"):
        body.sofrer_dano(1)
        _iniciar_morte()
