extends CharacterBody2D

# Agente único com modo de spray e interação automática com o balde na missão final.
const FRAMES_AGUA: SpriteFrames = preload("res://agente_agua_frames.tres")
const FRAMES_SPRAY: SpriteFrames = preload("res://agente_spray_frames.tres")
const VELOCIDADE: float = 245.0
const MULT_CORRIDA: float = 1.55
const ATAQUE_ALCANCE: float = 180.0

var vida: int = 3
var vida_maxima: int = 3
var game_over: bool = false
var modo: int = 2  # 1 = balde, 2 = inseticida
var balde_pego: bool = false
var balde_cheio: bool = false
var pode_atacar: bool = true
var invulneravel: bool = false
var acao_em_andamento: bool = false
var direcao_ataque: Vector2 = Vector2.RIGHT
var ultima_direcao: Vector2 = Vector2.DOWN
var mosquitos_eliminados: int = 0
var simbolos_coletados: int = 0
var poder_cruzeiro_ativo: bool = false
var vida_maxima_base: int = 3
var poder_cruzeiro_id: int = 0

@onready var visual: AnimatedSprite2D = $Visual
@onready var balde_na_mao: Sprite2D = $BaldeNaMao
@onready var spray_visual: Node2D = $SprayVisual

func _ready() -> void:
    visual.animation_finished.connect(_animacao_terminou)
    mudar_modo(2)
    atualizar_hud()

func _unhandled_input(event: InputEvent) -> void:
    if game_over:
        return
    if not (event is InputEventKey and event.pressed and not event.echo):
        return
    if event.keycode == KEY_SPACE:
        if modo == 2:
            atacar()

func _physics_process(_delta: float) -> void:
    if game_over:
        velocity = Vector2.ZERO
        return

    var direcao: Vector2 = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
    if Input.is_key_pressed(KEY_A): direcao.x -= 1.0
    if Input.is_key_pressed(KEY_D): direcao.x += 1.0
    if Input.is_key_pressed(KEY_W): direcao.y -= 1.0
    if Input.is_key_pressed(KEY_S): direcao.y += 1.0
    direcao = direcao.limit_length(1.0)

    var correndo: bool = Input.is_key_pressed(KEY_SHIFT)
    var bonus_velocidade: float = 1.35 if poder_cruzeiro_ativo else 1.0
    velocity = direcao * VELOCIDADE * bonus_velocidade * (MULT_CORRIDA if correndo else 1.0)
    move_and_slide()
    # Limites do mapa (HUD ocupa a margem superior).
    global_position.x = clampf(global_position.x, 28.0, 1124.0)
    global_position.y = clampf(global_position.y, 106.0, 621.0)

    if direcao.length() > 0.15:
        ultima_direcao = direcao
        direcao_ataque = direcao
        if not acao_em_andamento:
            if correndo:
                if modo == 1:
                    tocar("correr")
                elif absf(direcao.x) > absf(direcao.y):
                    tocar("correr_direita" if direcao.x > 0.0 else "correr_esquerda")
                elif direcao.y < 0.0:
                    tocar("correr_cima")
                else:
                    tocar("correr_baixo")
            elif absf(direcao.x) > absf(direcao.y):
                tocar("andar_direita" if direcao.x > 0 else "andar_esquerda")
            elif direcao.y < 0:
                tocar("andar_cima")
            else:
                tocar("andar_baixo")
    elif not acao_em_andamento:
        tocar_animacao_parado()

    if modo == 1:
        # Animacao 'com_balde' ja traz o balde desenhado; demais movimentos o exibem como acessorio.
        balde_na_mao.visible = balde_pego and not (visual.animation in ["com_balde", "pegar_balde", "pegar_agua"])
    else:
        balde_na_mao.visible = false

func mudar_modo(novo_modo: int) -> void:
    if modo == novo_modo and visual.sprite_frames != null:
        return
    modo = novo_modo
    acao_em_andamento = false
    visual.sprite_frames = FRAMES_AGUA if modo == 1 else FRAMES_SPRAY
    visual.flip_h = false
    tocar_animacao_parado()
    atualizar_hud()

func tocar(nome: String) -> void:
    if not visual.sprite_frames.has_animation(nome):
        return
    # O agente do spray possui sprites próprios para esquerda e direita; só o modo balde
    # conserva o espelhamento legado.
    var espelhar: bool = modo == 1 and (nome == "andar_esquerda" or (nome in ["correr", "parado_lado"] and ultima_direcao.x < 0.0))
    visual.flip_h = espelhar
    if visual.animation != nome or not visual.is_playing():
        visual.play(nome)

func tocar_animacao_parado() -> void:
    visual.flip_h = ultima_direcao.x < -0.2
    if modo == 1:
        if balde_pego:
            tocar("com_balde")
        elif ultima_direcao.y < -0.5:
            tocar("parado_costas")
        elif absf(ultima_direcao.x) > 0.5:
            tocar("parado_lado")
        else:
            tocar("parado_frente")
    elif ultima_direcao.y < -0.5:
        tocar("parado_costas")
    elif absf(ultima_direcao.x) > 0.5:
        tocar("parado_direita" if ultima_direcao.x > 0.0 else "parado_esquerda")
    else:
        tocar("parado")

func tocar_interacao(nome: String) -> void:
    if game_over:
        return
    acao_em_andamento = true
    visual.flip_h = (nome == "atirar" and modo == 2 and direcao_ataque.x < -0.1)
    visual.play(nome)

func _animacao_terminou() -> void:
    if game_over:
        return
    acao_em_andamento = false
    tocar_animacao_parado()

func atacar() -> void:
    if not pode_atacar or game_over or modo != 2:
        return
    pode_atacar = false
    OMZAudio.play_sfx("spray", -2.0)
    tocar_interacao("atirar")
    spray_visual.rotation = direcao_ataque.angle()
    spray_visual.visible = true
    spray_visual.iniciar()
    # Teste geometrico de cone, robusto mesmo sem sobreposicao previa de Area2D.
    var acertos: int = 0
    for mosquito in get_tree().get_nodes_in_group("mosquitos"):
        if not is_instance_valid(mosquito):
            continue
        var deslocamento: Vector2 = mosquito.global_position - global_position
        var distancia: float = deslocamento.length()
        if distancia > ATAQUE_ALCANCE:
            continue
        if distancia < 44.0 or direcao_ataque.dot(deslocamento.normalized()) >= 0.42:
            var dano_spray: int = 2 if poder_cruzeiro_ativo else 1
            if mosquito.has_method("receber_spray"):
                if mosquito.receber_spray(dano_spray):
                    acertos += 1
            else:
                mosquito.queue_free()
                acertos += 1
    if acertos > 0:
        mosquitos_eliminados += acertos
        if get_parent().has_method("ganhar_pontos"):
            get_parent().ganhar_pontos(acertos * 10)
    atualizar_hud()
    await get_tree().create_timer(0.30 if poder_cruzeiro_ativo else 0.65).timeout
    if is_inside_tree():
        pode_atacar = true

func sofrer_dano(quantidade: int = 1) -> void:
    if game_over or invulneravel:
        return
    invulneravel = true
    OMZAudio.play_sfx("dano", -1.0)
    vida = maxi(0, vida - quantidade)
    atualizar_hud()
    if vida <= 0:
        morrer()
    else:
        if modo != 2:
            mudar_modo(2)
        tocar_interacao("ferido")
        mostrar_mensagem("Cuidado! O mosquito atingiu voce.")
    await get_tree().create_timer(0.85).timeout
    if is_inside_tree():
        invulneravel = false

func recuperar_vida(quantidade: int = 1) -> void:
    if game_over:
        return
    var antes: int = vida
    vida = mini(vida_maxima, vida + quantidade)
    if vida > antes:
        OMZAudio.play_sfx("vida", -1.0)
        mudar_modo(2)
        tocar_interacao("coletar_kit")
        mostrar_mensagem("+1 VIDA!")
    atualizar_hud()

func coletar_cruzeiro() -> void:
    if game_over:
        return
    simbolos_coletados += 1
    OMZAudio.play_sfx("coleta", -1.0)
    mudar_modo(2)
    tocar_interacao("coletar_cruzeiro")
    if get_parent().has_method("ganhar_pontos"):
        get_parent().ganhar_pontos(25)

    # O simbolo concede um impulso temporario de 5 segundos.
    if not poder_cruzeiro_ativo:
        vida_maxima_base = vida_maxima
    poder_cruzeiro_ativo = true
    vida_maxima = vida_maxima_base + 2
    vida = mini(vida_maxima, vida + 2)
    visual.modulate = Color(1.0, 0.68, 0.22, 1.0)
    _efeito_energia_cruzeiro()
    mostrar_mensagem("PODER CRUZEIRO! +2 VIDA | SPRAY REFORCADO POR 5s!")
    atualizar_hud()
    poder_cruzeiro_id += 1
    _iniciar_tempo_poder_cruzeiro(poder_cruzeiro_id)

func _efeito_energia_cruzeiro() -> void:
    var aura := CPUParticles2D.new()
    aura.name = "EnergiaCruzeiro"
    aura.amount = 22
    aura.lifetime = 0.55
    aura.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE
    aura.emission_sphere_radius = 24.0
    aura.direction = Vector2.UP
    aura.spread = 180.0
    aura.initial_velocity_min = 12.0
    aura.initial_velocity_max = 38.0
    aura.color = Color(1.0, 0.48, 0.08, 0.9)
    aura.position = Vector2(0, -28)
    add_child(aura)
    aura.emitting = true
    var pulso := create_tween().set_loops(5)
    pulso.tween_property(visual, "scale", Vector2(1.06, 1.06), 0.25)
    pulso.tween_property(visual, "scale", Vector2.ONE, 0.25)
    get_tree().create_timer(5.0).timeout.connect(func():
        if is_instance_valid(aura):
            aura.queue_free()
    )

func _iniciar_tempo_poder_cruzeiro(id_ativacao: int) -> void:
    # Reinicia os 5 segundos caso o jogador colete outro simbolo durante o efeito.
    var marcador := get_tree().create_timer(5.0)
    await marcador.timeout
    if not is_inside_tree() or game_over or id_ativacao != poder_cruzeiro_id:
        return
    poder_cruzeiro_ativo = false
    vida_maxima = vida_maxima_base
    vida = mini(vida, vida_maxima)
    visual.modulate = Color.WHITE
    atualizar_hud()
    mostrar_mensagem("O poder Cruzeiro terminou.")

func pegar_balde() -> void:
    OMZAudio.play_sfx("coleta", -2.0)
    mudar_modo(1)
    balde_pego = true
    balde_cheio = false
    tocar_interacao("pegar_balde")
    mostrar_mensagem("Balde coletado! Procure o pneu com agua.")
    atualizar_hud()

func pegar_agua() -> void:
    if not balde_pego or balde_cheio:
        return
    mudar_modo(1)
    balde_cheio = true
    OMZAudio.play_sfx("agua", -1.0)
    tocar_interacao("pegar_agua")
    mostrar_mensagem("Agua coletada! Leve ao ponto de descarte.")
    atualizar_hud()

func descartar_agua() -> void:
    if not balde_cheio:
        return
    balde_cheio = false
    if get_parent().has_method("ganhar_pontos"):
        get_parent().ganhar_pontos(50)
    mostrar_mensagem("Agua descartada com seguranca! +50 pontos")
    atualizar_hud()

func morrer() -> void:
    game_over = true
    velocity = Vector2.ZERO
    modo = 2
    acao_em_andamento = true
    balde_na_mao.visible = false
    visual.sprite_frames = FRAMES_SPRAY
    visual.flip_h = false
    visual.play("morrer")
    await get_tree().create_timer(0.78).timeout
    if is_inside_tree() and get_parent().has_method("mostrar_game_over"):
        get_parent().mostrar_game_over()

func mostrar_mensagem(texto: String) -> void:
    if get_parent().has_method("mostrar_mensagem"):
        get_parent().mostrar_mensagem(texto)

func atualizar_hud() -> void:
    if get_parent() and get_parent().has_method("atualizar_hud"):
        get_parent().atualizar_hud()
