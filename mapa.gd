extends Control

const MOSQUITO: PackedScene = preload("res://mosquito.tscn")
const CHEFE: PackedScene = preload("res://chefe.tscn")
const KIT_VIDA: PackedScene = preload("res://kit_vida.tscn")
const SIMBOLO: PackedScene = preload("res://simbolo_cruzeiro.tscn")
const NUMERO_ONDAS: int = 7

var onda: int = 1
var proxima_onda: bool = false
var jogo_concluido: bool = false
var pontuacao: int = 0
var kit_vida_atual: Node2D = null
var simbolo_atual: Node2D = null
var mensagem_indice: int = 0
var chefe_derrotado: bool = false
var balde_coletado: bool = false
var interacao_final_em_andamento: bool = false
var powerup_chefe_gerado: bool = false
var indice_licao: int = 0
var painel_licao: Panel
var titulo_licao: Label
var texto_licao: Label
var tela_final_criada: bool = false
var tela_pausa: Control
var jogo_pausado: bool = false
var painel_transicao_onda: Panel
var titulo_transicao_onda: Label
var subtitulo_transicao_onda: Label
var indicador_onda: Panel
var token_transicao_onda: int = 0
var painel_controles: Panel
var objetos_coletaveis: Array[Dictionary] = []
var coletaveis_liberados: int = 0
var pontos_label: Label
var pontos_fundo: Panel
var barra_chefe: ProgressBar
var label_chefe: Label

const BALDE_POS := Vector2(943, 171)
const PNEU_POS := Vector2(790, 154)

@onready var jogador = $Jogador
@onready var pneu = $Terreno/Pneu
@onready var balde_mapa: TextureRect = $Terreno/Balde

func _ready() -> void:
    randomize()
    $GameOverLabel.visible = false
    $GameOverFundo.visible = false
    balde_mapa.visible = false
    _montar_hud()
    _criar_objetos_coletaveis()
    _revelar_coletaveis_da_onda()
    spawn_mosquitos(5)
    criar_kit_vida()
    criar_simbolo()
    atualizar_hud()
    mostrar_mensagem("Elimine os mosquitos para avançar. Use E perto dos objetos para ganhar pontos extras.")
    _mostrar_licao(_texto_educativo_da_onda(onda))

func _unhandled_input(event: InputEvent) -> void:
    if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE:
        if not jogo_concluido and not jogador.game_over:
            _alternar_pausa()
        return
    if jogo_concluido or jogador.game_over or jogo_pausado:
        return
    if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_E:
        interagir()

func _alternar_pausa() -> void:
    if jogo_concluido or jogador.game_over:
        return
    if jogo_pausado:
        _fechar_pausa()
    else:
        _abrir_pausa()

func _abrir_pausa() -> void:
    if is_instance_valid(tela_pausa):
        return

    jogo_pausado = true
    jogador.set_physics_process(false)

    var fundo := ColorRect.new()
    fundo.name = "OverlayPausa"
    fundo.color = Color(0.005, 0.025, 0.035, 0.82)
    fundo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    fundo.z_index = 120
    fundo.process_mode = Node.PROCESS_MODE_ALWAYS
    fundo.mouse_filter = Control.MOUSE_FILTER_STOP
    add_child(fundo)
    tela_pausa = fundo
    var entrada_esc := Control.new()
    entrada_esc.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    entrada_esc.mouse_filter = Control.MOUSE_FILTER_IGNORE
    entrada_esc.process_mode = Node.PROCESS_MODE_ALWAYS
    entrada_esc.set_script(load("res://pause_overlay_input.gd"))
    entrada_esc.connect("fechar_pausa", _fechar_pausa)
    fundo.add_child(entrada_esc)
    get_tree().paused = true

    var painel := _criar_painel_overlay(fundo, Vector2(306, 67), Vector2(540, 514), Color("#b6ff55"))
    var coluna := _criar_coluna_overlay(painel, Vector2(30, 20), Vector2(480, 474), 7)

    _adicionar_logo_overlay(coluna, Vector2(178, 92))
    coluna.add_child(_criar_titulo_overlay("MISSÃO PAUSADA", 29, Color("#f1ffd8")))
    coluna.add_child(_criar_subtitulo_overlay("Respire, prepare-se e continue a proteger a comunidade.", 16))
    _adicionar_divisor_overlay(coluna, Color("#ffb23e"))
    _adicionar_card_overlay(
        coluna,
        "Sua missão continua exatamente de onde você parou.\nPressione ESC para voltar à ação.",
        58,
        Color("#ffbd45")
    )

    var continuar := _criar_botao_overlay("▶  CONTINUAR MISSÃO", false, Vector2(470, 48))
    continuar.pressed.connect(func(): _fechar_pausa())
    coluna.add_child(continuar)

    var reiniciar := _criar_botao_overlay("↻  REINICIAR PARTIDA", true, Vector2(470, 48))
    reiniciar.pressed.connect(func():
        get_tree().paused = false
        get_tree().reload_current_scene()
    )
    coluna.add_child(reiniciar)

    var menu := _criar_botao_overlay("⌂  VOLTAR AO MENU INICIAL", false, Vector2(470, 48))
    menu.pressed.connect(func():
        get_tree().paused = false
        get_tree().change_scene_to_file("res://main.tscn")
    )
    coluna.add_child(menu)

    var rodape := _criar_rodape_overlay("OPERAÇÃO MOSQUITO ZERO  •  ESC PARA CONTINUAR")
    coluna.add_child(rodape)

func _fechar_pausa() -> void:
    if is_instance_valid(tela_pausa):
        tela_pausa.queue_free()
    tela_pausa = null
    jogo_pausado = false
    get_tree().paused = false
    jogador.set_physics_process(true)

func _mostrar_tela_final(vitoria: bool) -> void:
    if tela_final_criada:
        return
    tela_final_criada = true
    $GameOverFundo.visible = false
    $GameOverLabel.visible = false

    var fundo := ColorRect.new()
    fundo.name = "OverlayResultado"
    fundo.color = Color(0.005, 0.025, 0.035, 0.86)
    fundo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    fundo.z_index = 150
    fundo.mouse_filter = Control.MOUSE_FILTER_STOP
    add_child(fundo)

    var cor_destaque := Color("#ffcf58") if vitoria else Color("#ff9b78")
    var painel := _criar_painel_overlay(fundo, Vector2(216, 45), Vector2(720, 558), cor_destaque)
    var coluna := _criar_coluna_overlay(painel, Vector2(34, 15), Vector2(652, 528), 7)

    _adicionar_logo_overlay(coluna, Vector2(190, 118))

    var titulo_texto := "MISSÃO CUMPRIDA!" if vitoria else "NÃO DESISTA, AGENTE!"
    coluna.add_child(_criar_titulo_overlay(titulo_texto, 35, cor_destaque))

    var mensagem := "Você ajudou a combater o mosquito da dengue!" if vitoria else "Desta vez os mosquitos venceram, mas a comunidade ainda conta com você!"
    coluna.add_child(_criar_subtitulo_overlay(mensagem, 18))
    _adicionar_divisor_overlay(coluna, cor_destaque)

    var dica := "Água parada não pode esperar! Tampe caixas-d'água, proteja pneus da chuva e elimine recipientes que acumulam água." if vitoria else "Dica de agente: movimente-se pelo quintal, mantenha distância dos mosquitos e aproveite os kits de vida."
    _adicionar_card_overlay(coluna, dica, 68, cor_destaque)

    var pontuacao_card := _criar_card_container(coluna, 36, Color("#b6ff55"))
    var pontuacao_label := Label.new()
    pontuacao_label.text = "PONTUAÇÃO DA MISSÃO   •   %d PONTOS" % pontuacao
    pontuacao_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    pontuacao_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    pontuacao_label.add_theme_font_size_override("font_size", 18)
    pontuacao_label.add_theme_color_override("font_color", Color("#fff3c8"))
    pontuacao_card.add_child(pontuacao_label)

    var jogar_texto := "JOGAR NOVAMENTE" if vitoria else "TENTAR NOVAMENTE"
    var jogar := _criar_botao_overlay("↻  " + jogar_texto, true, Vector2(640, 48))
    jogar.pressed.connect(func(): get_tree().reload_current_scene())
    coluna.add_child(jogar)

    var menu := _criar_botao_overlay("⌂  VOLTAR AO MENU INICIAL", false, Vector2(640, 48))
    menu.pressed.connect(func(): get_tree().change_scene_to_file("res://main.tscn"))
    coluna.add_child(menu)

    var rodape_texto := "OBRIGADO POR FAZER PARTE DESSA MISSÃO!" if vitoria else "CADA NOVA TENTATIVA É UMA CHANCE DE APRENDER."
    coluna.add_child(_criar_rodape_overlay(rodape_texto))

func _criar_painel_overlay(pai: Control, posicao: Vector2, tamanho: Vector2, cor_borda: Color) -> Panel:
    var painel := Panel.new()
    painel.position = posicao
    painel.size = tamanho
    painel.z_index = 1
    painel.add_theme_stylebox_override("panel", _estilo_painel_final(cor_borda))
    pai.add_child(painel)
    return painel

func _criar_coluna_overlay(painel: Panel, posicao: Vector2, tamanho: Vector2, separacao: int) -> VBoxContainer:
    var coluna := VBoxContainer.new()
    coluna.position = posicao
    coluna.size = tamanho
    coluna.add_theme_constant_override("separation", separacao)
    coluna.alignment = BoxContainer.ALIGNMENT_CENTER
    painel.add_child(coluna)
    return coluna

func _adicionar_logo_overlay(pai: VBoxContainer, tamanho: Vector2) -> void:
    var centralizar := CenterContainer.new()
    centralizar.custom_minimum_size = Vector2(0, tamanho.y)
    centralizar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    pai.add_child(centralizar)

    var logo := TextureRect.new()
    logo.texture = load("res://assets/ui/logo_operacao.png") as Texture2D
    logo.custom_minimum_size = tamanho
    logo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    logo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
    logo.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
    centralizar.add_child(logo)

func _criar_titulo_overlay(texto: String, tamanho: int, cor: Color) -> Label:
    var label := Label.new()
    label.text = texto
    label.custom_minimum_size = Vector2(0, 42)
    label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    label.add_theme_font_size_override("font_size", tamanho)
    label.add_theme_color_override("font_color", cor)
    label.add_theme_color_override("font_outline_color", Color("#073b2c"))
    label.add_theme_constant_override("outline_size", 5)
    return label

func _criar_subtitulo_overlay(texto: String, tamanho: int = 17) -> Label:
    var label := Label.new()
    label.text = texto
    label.custom_minimum_size = Vector2(0, 34 if tamanho <= 17 else 42)
    label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    label.add_theme_font_size_override("font_size", tamanho)
    label.add_theme_color_override("font_color", Color("#efffe8"))
    return label

func _adicionar_divisor_overlay(pai: VBoxContainer, cor: Color) -> void:
    var divisor := ColorRect.new()
    divisor.custom_minimum_size = Vector2(0, 4)
    divisor.color = cor
    divisor.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    pai.add_child(divisor)

func _adicionar_card_overlay(pai: VBoxContainer, texto: String, altura: float, cor_borda: Color) -> void:
    var card := _criar_card_container(pai, altura, cor_borda)
    var label := Label.new()
    label.text = texto
    label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    label.size_flags_vertical = Control.SIZE_EXPAND_FILL
    label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    label.add_theme_font_size_override("font_size", 17)
    label.add_theme_color_override("font_color", Color("#f3ffec"))
    card.add_child(label)

func _criar_card_container(pai: VBoxContainer, altura: float, cor_borda: Color) -> PanelContainer:
    var card := PanelContainer.new()
    card.custom_minimum_size = Vector2(0, altura)
    card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    var estilo := StyleBoxFlat.new()
    estilo.bg_color = Color("#07503d")
    estilo.border_color = cor_borda
    estilo.set_border_width_all(2)
    estilo.set_corner_radius_all(12)
    estilo.content_margin_left = 16
    estilo.content_margin_right = 16
    estilo.content_margin_top = 8
    estilo.content_margin_bottom = 8
    estilo.shadow_color = Color(0, 0, 0, 0.34)
    estilo.shadow_size = 5
    card.add_theme_stylebox_override("panel", estilo)
    pai.add_child(card)
    return card

func _criar_botao_overlay(texto: String, laranja: bool, tamanho: Vector2) -> Button:
    var botao := Button.new()
    botao.text = texto
    botao.pressed.connect(func(): OMZAudio.play_sfx("botao", -5.0))
    botao.custom_minimum_size = tamanho
    botao.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    botao.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
    botao.focus_mode = Control.FOCUS_NONE
    _estilizar_botao_final(botao, laranja)
    return botao

func _criar_rodape_overlay(texto: String) -> Label:
    var label := Label.new()
    label.text = texto
    label.custom_minimum_size = Vector2(0, 20)
    label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    label.add_theme_font_size_override("font_size", 12)
    label.add_theme_color_override("font_color", Color("#b9d7b5"))
    return label

func _estilo_painel_final(cor_borda: Color = Color("#b6ff55")) -> StyleBoxFlat:
    var estilo := StyleBoxFlat.new()
    estilo.bg_color = Color("#052c25")
    estilo.border_color = cor_borda
    estilo.set_border_width_all(6)
    estilo.set_corner_radius_all(20)
    estilo.shadow_color = Color(0, 0, 0, 0.70)
    estilo.shadow_size = 18
    estilo.content_margin_left = 22
    estilo.content_margin_right = 22
    estilo.content_margin_top = 15
    estilo.content_margin_bottom = 15
    return estilo

func _estilizar_botao_final(botao: Button, laranja: bool = false) -> void:
    botao.add_theme_font_size_override("font_size", 19)
    botao.add_theme_color_override("font_color", Color("#ffffff"))
    botao.add_theme_color_override("font_hover_color", Color("#fff4b6"))
    botao.add_theme_color_override("font_pressed_color", Color("#ffffff"))
    botao.add_theme_color_override("font_outline_color", Color("#073b2c"))
    botao.add_theme_constant_override("outline_size", 2)
    botao.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND

    var normal := StyleBoxFlat.new()
    normal.bg_color = Color("#087b43") if not laranja else Color("#c76b12")
    normal.border_color = Color("#b6ff55") if not laranja else Color("#ffe17b")
    normal.set_border_width_all(4)
    normal.set_corner_radius_all(10)
    normal.shadow_color = Color(0.0, 0.0, 0.0, 0.42)
    normal.shadow_size = 5
    normal.content_margin_left = 12
    normal.content_margin_right = 12
    normal.content_margin_top = 8
    normal.content_margin_bottom = 8

    var hover := normal.duplicate() as StyleBoxFlat
    hover.bg_color = Color("#149d56") if not laranja else Color("#ed8a1e")
    hover.border_color = Color("#efff9b")
    hover.shadow_size = 8

    var pressionado := normal.duplicate() as StyleBoxFlat
    pressionado.bg_color = Color("#075b36") if not laranja else Color("#a9500c")
    pressionado.border_color = Color("#8eea43") if not laranja else Color("#ffd05c")
    pressionado.shadow_size = 2

    botao.add_theme_stylebox_override("normal", normal)
    botao.add_theme_stylebox_override("hover", hover)
    botao.add_theme_stylebox_override("pressed", pressionado)
    botao.add_theme_stylebox_override("focus", hover)

func interagir() -> void:
    if _coletar_objeto_proximo():
        return
    var onde: Vector2 = jogador.global_position

    if chefe_derrotado and not balde_coletado and onde.distance_to(BALDE_POS) <= 100.0:
        balde_coletado = true
        OMZAudio.play_sfx("coleta", -1.0)
        balde_mapa.visible = false
        jogador.pegar_balde()
        mostrar_mensagem("Balde coletado! Vá até o pneu com água parada.")
        atualizar_hud()
        return
    if balde_coletado and onde.distance_to(PNEU_POS) <= 105.0 and not interacao_final_em_andamento:
        interacao_final_em_andamento = true
        jogador.mudar_modo(1)
        OMZAudio.play_sfx("agua", -1.0)
        jogador.tocar_interacao("pegar_agua")
        mostrar_mensagem("Retirando a água parada...")
        pneu.esvaziar()
        await get_tree().create_timer(1.9).timeout
        if is_inside_tree() and not jogador.game_over:
            finalizar_jogo()
        return
    if chefe_derrotado and not balde_coletado:
        mostrar_mensagem("Aproxime-se do balde deixado pelo chefe e pressione E.")
    elif balde_coletado:
        mostrar_mensagem("Aproxime-se do pneu e pressione E para eliminar a água parada.")
    else:
        mostrar_mensagem("Continue combatendo os mosquitos!")

func _process(_delta: float) -> void:
    if not jogo_concluido and not jogador.game_over and not jogo_pausado:
        _atualizar_marcadores_coleta()

    if jogo_concluido or jogador.game_over or proxima_onda or chefe_derrotado:
        return

    # A onda avança somente quando todos os mosquitos forem eliminados.
    # Os objetos colecionáveis são opcionais e nunca bloqueiam a progressão.
    if get_tree().get_nodes_in_group("mosquitos").is_empty():
        if onda >= NUMERO_ONDAS:
            return
        iniciar_proxima_onda()

func spawn_mosquitos(quantidade: int) -> void:
    var posicoes := [Vector2(540, 148), Vector2(672, 205), Vector2(875, 322), Vector2(987, 396), Vector2(565, 509)]
    for i in range(quantidade):
        var mosquito = MOSQUITO.instantiate()
        add_child(mosquito)
        mosquito.global_position = posicoes[i % posicoes.size()] + Vector2(randf_range(-35.0, 35.0), randf_range(-35.0, 35.0))
        mosquito.configurar_onda(onda)

func iniciar_proxima_onda() -> void:
    proxima_onda = true
    onda += 1
    OMZAudio.play_sfx("onda", -1.0)
    atualizar_hud()
    $OndaMensagemLabel.visible = false
    _mostrar_cartao_transicao_onda()
    _revelar_coletaveis_da_onda()

    _mostrar_licao(_texto_educativo_da_onda(onda))

    await get_tree().create_timer(1.65).timeout
    if not is_inside_tree() or jogador.game_over:
        return
    if onda == 7:
        iniciar_chefe()
    else:
        var quantidades := {2: 7, 3: 9, 4: 11, 5: 13, 6: 15}
        spawn_mosquitos(quantidades.get(onda, 7))
        criar_kit_vida()
        criar_simbolo()
    proxima_onda = false
    atualizar_hud()

func iniciar_chefe() -> void:
    OMZAudio.play_sfx("chefe", -1.0)
    mostrar_mensagem("ALERTA! O MOSQUITO-MÃE CHEGOU! Prepare seu spray!")
    if is_instance_valid(simbolo_atual):
        simbolo_atual.queue_free()
        simbolo_atual = null
    var chefe = CHEFE.instantiate()
    add_child(chefe)
    chefe.global_position = Vector2(850, 240)
    chefe.vida_alterada.connect(_atualizar_barra_chefe)
    chefe.derrotado.connect(_ao_derrotar_chefe)
    barra_chefe.visible = true
    label_chefe.visible = true
    _atualizar_barra_chefe(30, 30)
    # O power-up Cruzeiro aparece durante a luta, como recurso de recuperação.
    _gerar_powerup_durante_chefe()

func _gerar_powerup_durante_chefe() -> void:
    await get_tree().create_timer(3.0).timeout
    if not is_inside_tree() or chefe_derrotado or powerup_chefe_gerado:
        return
    powerup_chefe_gerado = true
    simbolo_atual = SIMBOLO.instantiate()
    add_child(simbolo_atual)
    simbolo_atual.global_position = Vector2(580, 465)
    mostrar_mensagem("ENERGIA CRUZEIRO! Colete a estrela para recuperar vida e fortalecer o spray!")

func _atualizar_barra_chefe(atual: int, maxima: int) -> void:
    if not is_instance_valid(barra_chefe):
        return
    barra_chefe.max_value = maxima
    barra_chefe.value = atual
    label_chefe.text = "MOSQUITO-MÃE  %d / %d" % [atual, maxima]

func _ao_derrotar_chefe() -> void:
    chefe_derrotado = true
    barra_chefe.visible = false
    label_chefe.visible = false
    balde_mapa.visible = true
    balde_mapa.position = Vector2(205, 68)
    mostrar_mensagem("Chefe derrotado! Pegue o balde que ele deixou cair.")

func finalizar_jogo() -> void:
    OMZAudio.play_sfx("vitoria", -1.0)
    jogo_concluido = true
    jogador.game_over = true
    jogador.velocity = Vector2.ZERO
    _mostrar_tela_final(true)

func mostrar_game_over() -> void:
    if tela_final_criada:
        return
    jogo_concluido = true
    OMZAudio.play_sfx("derrota", -1.0)
    _mostrar_tela_final(false)


func _reiniciar() -> void:
    get_tree().reload_current_scene()

func criar_kit_vida() -> void:
    if is_instance_valid(kit_vida_atual):
        return
    kit_vida_atual = KIT_VIDA.instantiate()
    add_child(kit_vida_atual)
    kit_vida_atual.global_position = _posicao_livre(190.0)

func criar_simbolo() -> void:
    if is_instance_valid(simbolo_atual):
        return
    # Item especial raro: chance baixa por onda, sem aparicoes consecutivas garantidas.
    if randf() > 0.30:
        return
    simbolo_atual = SIMBOLO.instantiate()
    add_child(simbolo_atual)
    simbolo_atual.global_position = _posicao_livre(240.0)

func _posicao_livre(distancia: float) -> Vector2:
    var posicao := Vector2(600, 492)
    for tentativa in range(50):
        posicao = Vector2(randf_range(430.0, 1080.0), randf_range(290.0, 574.0))
        if posicao.distance_to(jogador.global_position) >= distancia and posicao.distance_to(PNEU_POS) >= 80.0:
            break
    return posicao

func item_coletado(item: Node2D) -> void:
    if item == kit_vida_atual:
        kit_vida_atual = null
    elif item == simbolo_atual:
        simbolo_atual = null

func ganhar_pontos(quantidade: int) -> void:
    pontuacao += quantidade
    atualizar_hud()

func atualizar_hud() -> void:
    if not is_node_ready() or not is_instance_valid(jogador):
        return
    $BarraHP.value = float(jogador.vida) / float(jogador.vida_maxima) * 100.0
    $OndaLabel.text = "ONDA %d / 7" % onda
    if is_instance_valid(pontos_label):
        pontos_label.text = "★  PONTOS: %d" % pontuacao
        # A barra do chefe ocupa a região direita do HUD na sétima onda.
        pontos_label.visible = onda < 7 or chefe_derrotado
    if is_instance_valid(pontos_fundo):
        pontos_fundo.visible = onda < 7 or chefe_derrotado
    if is_instance_valid(label_chefe) and onda == 7 and not chefe_derrotado:
        label_chefe.visible = true

func _mostrar_cartao_transicao_onda() -> void:
    if not is_instance_valid(painel_transicao_onda):
        return

    token_transicao_onda += 1
    var token_atual := token_transicao_onda

    if onda == 7:
        titulo_transicao_onda.text = "ONDA 07  •  CHEFE FINAL"
        subtitulo_transicao_onda.text = "O MOSQUITO-MÃE ESTÁ CHEGANDO!"
        titulo_transicao_onda.add_theme_color_override("font_color", Color("#ffbd45"))
    else:
        titulo_transicao_onda.text = "ONDA %02d" % onda
        subtitulo_transicao_onda.text = "NOVOS MOSQUITOS SE APROXIMAM"
        titulo_transicao_onda.add_theme_color_override("font_color", Color("#f1ffd9"))

    painel_transicao_onda.visible = true
    painel_transicao_onda.position = Vector2(326, 188)
    painel_transicao_onda.scale = Vector2(0.92, 0.92)
    painel_transicao_onda.modulate = Color(1, 1, 1, 0)

    var entrada := create_tween()
    entrada.set_parallel(true)
    entrada.tween_property(painel_transicao_onda, "position", Vector2(326, 170), 0.24).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
    entrada.tween_property(painel_transicao_onda, "scale", Vector2.ONE, 0.26).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
    entrada.tween_property(painel_transicao_onda, "modulate:a", 1.0, 0.20)

    await get_tree().create_timer(1.24).timeout
    if not is_inside_tree() or token_atual != token_transicao_onda or not is_instance_valid(painel_transicao_onda):
        return

    var saida := create_tween()
    saida.tween_property(painel_transicao_onda, "modulate:a", 0.0, 0.20)
    saida.parallel().tween_property(painel_transicao_onda, "position", Vector2(326, 154), 0.20)
    await saida.finished
    if is_instance_valid(painel_transicao_onda) and token_atual == token_transicao_onda:
        painel_transicao_onda.visible = false


func _criar_objetos_coletaveis() -> void:
    # Objetos opcionais que podem acumular água. O pneu não aparece aqui:
    # ele continua reservado para a missão final após o Mosquito-mãe.
    # Escalas ajustadas para combinar com o tamanho do agente e dos mosquitos.
    # O tamanho visual é limitado explicitamente para manter os itens discretos na gameplay.
    var definicoes := [
        {"nome": "Vaso com pratinho", "arquivo": "vaso_pratinho.png", "centro": Vector2(145, 548), "tamanho": Vector2(30, 30), "pontos": 25},
        {"nome": "Balde com água", "arquivo": "balde_agua.png", "centro": Vector2(315, 525), "tamanho": Vector2(30, 30), "pontos": 30},
        {"nome": "Bacia com água", "arquivo": "bacia_agua.png", "centro": Vector2(515, 565), "tamanho": Vector2(30, 30), "pontos": 25},
        {"nome": "Recipiente aberto", "arquivo": "recipiente_aberto.png", "centro": Vector2(710, 520), "tamanho": Vector2(30, 30), "pontos": 20},
        {"nome": "Garrafa PET", "arquivo": "garrafa_pet.png", "centro": Vector2(850, 560), "tamanho": Vector2(30, 30), "pontos": 25},
        {"nome": "Lata com água", "arquivo": "lata_agua.png", "centro": Vector2(970, 505), "tamanho": Vector2(30, 30), "pontos": 20},
        {"nome": "Caixa térmica", "arquivo": "caixa_termica.png", "centro": Vector2(600, 480), "tamanho": Vector2(30, 30), "pontos": 30}
    ]

    for definicao in definicoes:
        var centro: Vector2 = definicao["centro"]
        var tamanho: Vector2 = definicao["tamanho"]

        var sprite := TextureRect.new()
        sprite.name = "Coletavel_" + str(definicao["nome"]).replace(" ", "")
        sprite.texture = load("res://assets/coletaveis/" + str(definicao["arquivo"])) as Texture2D
        sprite.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
        sprite.custom_minimum_size = Vector2.ZERO
        sprite.position = centro - tamanho * 0.5
        sprite.size = tamanho
        sprite.pivot_offset = tamanho * 0.5
        sprite.scale = Vector2.ONE
        sprite.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
        sprite.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
        sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
        sprite.mouse_filter = Control.MOUSE_FILTER_IGNORE
        sprite.z_index = -1
        sprite.visible = false
        add_child(sprite)

        # O indicador E só aparece quando o agente se aproxima do objeto.
        var marcador := Panel.new()
        marcador.name = "IndicadorColetar"
        marcador.position = Vector2(centro.x - 17.0, centro.y - tamanho.y * 0.5 - 30.0)
        marcador.size = Vector2(34, 27)
        marcador.z_index = 8
        marcador.visible = false
        marcador.mouse_filter = Control.MOUSE_FILTER_IGNORE
        var estilo := StyleBoxFlat.new()
        estilo.bg_color = Color("#063e32")
        estilo.border_color = Color("#ffbd45")
        estilo.set_border_width_all(2)
        estilo.set_corner_radius_all(8)
        estilo.shadow_color = Color(0, 0, 0, 0.45)
        estilo.shadow_size = 5
        marcador.add_theme_stylebox_override("panel", estilo)

        var tecla := Label.new()
        tecla.text = "E"
        tecla.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
        tecla.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        tecla.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
        tecla.add_theme_font_size_override("font_size", 18)
        tecla.add_theme_color_override("font_color", Color("#ffcf61"))
        marcador.add_child(tecla)
        add_child(marcador)

        objetos_coletaveis.append({
            "nome": str(definicao["nome"]),
            "centro": centro,
            "pontos": int(definicao["pontos"]),
            "sprite": sprite,
            "marcador": marcador,
            "coletado": false,
            "liberado": false
        })


func _revelar_coletaveis_da_onda() -> void:
    # Na primeira onda aparecem apenas dois. A cada nova onda, mais um
    # objeto é liberado, evitando que todos fiquem espalhados desde o início.
    var quantidade_alvo: int = mini(2 + onda - 1, objetos_coletaveis.size())
    while coletaveis_liberados < quantidade_alvo:
        var item: Dictionary = objetos_coletaveis[coletaveis_liberados]
        item["liberado"] = true
        objetos_coletaveis[coletaveis_liberados] = item

        var sprite := item["sprite"] as TextureRect
        if is_instance_valid(sprite):
            sprite.visible = true
            sprite.modulate.a = 0.0
            var entrada := sprite.create_tween()
            entrada.tween_property(sprite, "modulate:a", 1.0, 0.45)

        coletaveis_liberados += 1


func _atualizar_marcadores_coleta() -> void:
    if not is_instance_valid(jogador):
        return

    for item in objetos_coletaveis:
        if not bool(item.get("liberado", false)) or bool(item.get("coletado", false)):
            continue

        var marcador := item.get("marcador") as Panel
        if not is_instance_valid(marcador):
            continue

        var centro_item: Vector2 = item["centro"]
        var distancia: float = jogador.global_position.distance_to(centro_item)
        marcador.visible = distancia <= 112.0


func _coletar_objeto_proximo() -> bool:
    var indice_proximo := -1
    var menor_distancia := 96.0

    for i in range(objetos_coletaveis.size()):
        var candidato: Dictionary = objetos_coletaveis[i]
        if not bool(candidato.get("liberado", false)) or bool(candidato.get("coletado", false)):
            continue

        var distancia: float = jogador.global_position.distance_to(candidato["centro"])
        if distancia <= menor_distancia:
            menor_distancia = distancia
            indice_proximo = i

    if indice_proximo < 0:
        return false

    var escolhido: Dictionary = objetos_coletaveis[indice_proximo]
    escolhido["coletado"] = true
    objetos_coletaveis[indice_proximo] = escolhido

    var marcador: Panel = escolhido["marcador"] as Panel
    if is_instance_valid(marcador):
        marcador.queue_free()

    var sprite: TextureRect = escolhido["sprite"] as TextureRect
    if is_instance_valid(sprite):
        var animacao := sprite.create_tween()
        animacao.tween_property(sprite, "scale", Vector2(1.22, 1.22), 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
        animacao.tween_property(sprite, "modulate:a", 0.0, 0.22)
        animacao.tween_callback(sprite.queue_free)

    var pontos: int = int(escolhido["pontos"])
    OMZAudio.play_sfx("coleta", -2.0)
    ganhar_pontos(pontos)
    mostrar_mensagem("%s recolhido! +%d pontos. Não deixe água parada!" % [str(escolhido["nome"]), pontos])
    return true


func _texto_educativo_da_onda(numero: int) -> String:
    var licoes := {
        1: "O Aedes aegypti costuma picar durante o dia e vive perto das casas.",
        2: "Ele pode transmitir dengue, zika e chikungunya. Elimine criadouros e evite picadas.",
        3: "A fêmea coloca ovos nas paredes dos recipientes, perto da linha da água.",
        4: "Os ovos podem resistir por meses em locais secos. Lave o recipiente ao esvaziá-lo.",
        5: "Caixas-d'água e tonéis devem ficar bem tampados, sem frestas.",
        6: "Pneus, garrafas e latas juntam chuva. Guarde cobertos ou descarte corretamente.",
        7: "Eliminar focos de água parada interrompe o ciclo do mosquito e protege a vizinhança."
    }
    return str(licoes.get(numero, "Eliminar a água parada ajuda a proteger toda a comunidade."))


func _mostrar_licao(conteudo: String) -> void:
    if not is_instance_valid(painel_licao) or not is_instance_valid(texto_licao):
        return

    indice_licao += 1
    var id_atual := indice_licao

    texto_licao.text = conteudo
    painel_licao.visible = true
    painel_licao.position = Vector2(-380, 82)
    painel_licao.modulate = Color(1, 1, 1, 0)

    var aparecer := create_tween()
    aparecer.set_parallel(true)
    aparecer.tween_property(painel_licao, "position", Vector2(18, 82), 0.28).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
    aparecer.tween_property(painel_licao, "modulate:a", 1.0, 0.22)
    await aparecer.finished

    await get_tree().create_timer(4.8).timeout
    if is_inside_tree() and id_atual == indice_licao and is_instance_valid(painel_licao):
        var sumir := create_tween()
        sumir.tween_property(painel_licao, "modulate:a", 0.0, 0.28)
        await sumir.finished
        painel_licao.visible = false


func _estilo_cartao_menu(cor_borda: Color = Color("#b6ff55")) -> StyleBoxFlat:
    var estilo := StyleBoxFlat.new()
    estilo.bg_color = Color(0.015, 0.12, 0.09, 0.97)
    estilo.border_color = cor_borda
    estilo.set_border_width_all(4)
    estilo.set_corner_radius_all(14)
    estilo.shadow_color = Color(0.0, 0.0, 0.0, 0.55)
    estilo.shadow_size = 10
    estilo.content_margin_left = 14
    estilo.content_margin_right = 14
    estilo.content_margin_top = 8
    estilo.content_margin_bottom = 8
    return estilo

func mostrar_mensagem(texto: String) -> void:
    var aviso: Label = get_node_or_null("MensagemLabel")
    if aviso == null:
        return
    mensagem_indice += 1
    var meu_indice: int = mensagem_indice
    aviso.text = texto
    aviso.visible = true
    await get_tree().create_timer(3.25).timeout
    if is_inside_tree() and meu_indice == mensagem_indice:
        aviso.visible = false

func _criar_cartao_transicao_onda() -> void:
    painel_transicao_onda = Panel.new()
    painel_transicao_onda.name = "CartaoTransicaoOnda"
    painel_transicao_onda.position = Vector2(326, 170)
    painel_transicao_onda.size = Vector2(500, 112)
    painel_transicao_onda.z_index = 95
    painel_transicao_onda.visible = false
    painel_transicao_onda.mouse_filter = Control.MOUSE_FILTER_IGNORE
    painel_transicao_onda.add_theme_stylebox_override("panel", _estilo_cartao_menu())
    add_child(painel_transicao_onda)

    var faixa := ColorRect.new()
    faixa.position = Vector2(18, 13)
    faixa.size = Vector2(7, 84)
    faixa.color = Color("#ff9f2e")
    faixa.mouse_filter = Control.MOUSE_FILTER_IGNORE
    painel_transicao_onda.add_child(faixa)

    titulo_transicao_onda = Label.new()
    titulo_transicao_onda.position = Vector2(38, 14)
    titulo_transicao_onda.size = Vector2(440, 44)
    titulo_transicao_onda.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    titulo_transicao_onda.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    titulo_transicao_onda.add_theme_font_size_override("font_size", 29)
    titulo_transicao_onda.add_theme_color_override("font_color", Color("#f1ffd9"))
    titulo_transicao_onda.add_theme_color_override("font_outline_color", Color("#063b2b"))
    titulo_transicao_onda.add_theme_constant_override("outline_size", 4)
    painel_transicao_onda.add_child(titulo_transicao_onda)

    var divisor := ColorRect.new()
    divisor.position = Vector2(65, 62)
    divisor.size = Vector2(370, 2)
    divisor.color = Color("#df9632")
    divisor.mouse_filter = Control.MOUSE_FILTER_IGNORE
    painel_transicao_onda.add_child(divisor)

    subtitulo_transicao_onda = Label.new()
    subtitulo_transicao_onda.position = Vector2(32, 69)
    subtitulo_transicao_onda.size = Vector2(450, 25)
    subtitulo_transicao_onda.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    subtitulo_transicao_onda.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    subtitulo_transicao_onda.add_theme_font_size_override("font_size", 14)
    subtitulo_transicao_onda.add_theme_color_override("font_color", Color("#e3f6d5"))
    painel_transicao_onda.add_child(subtitulo_transicao_onda)


func _criar_cartao_licao() -> void:
    painel_licao = Panel.new()
    painel_licao.name = "PainelLicao"
    painel_licao.position = Vector2(18, 82)
    painel_licao.size = Vector2(350, 142)
    painel_licao.z_index = 72
    painel_licao.visible = false
    painel_licao.mouse_filter = Control.MOUSE_FILTER_IGNORE
    painel_licao.clip_contents = true
    painel_licao.add_theme_stylebox_override("panel", _estilo_cartao_menu())
    add_child(painel_licao)

    var acento := ColorRect.new()
    acento.position = Vector2(12, 11)
    acento.size = Vector2(5, 120)
    acento.color = Color("#ff9f2e")
    acento.mouse_filter = Control.MOUSE_FILTER_IGNORE
    painel_licao.add_child(acento)

    titulo_licao = Label.new()
    titulo_licao.text = "VOCÊ SABIA?"
    titulo_licao.position = Vector2(27, 9)
    titulo_licao.size = Vector2(300, 28)
    titulo_licao.add_theme_font_size_override("font_size", 18)
    titulo_licao.add_theme_color_override("font_color", Color("#ffbd45"))
    painel_licao.add_child(titulo_licao)

    var linha := ColorRect.new()
    linha.position = Vector2(27, 38)
    linha.size = Vector2(300, 2)
    linha.color = Color("#8fcf49")
    linha.mouse_filter = Control.MOUSE_FILTER_IGNORE
    painel_licao.add_child(linha)

    texto_licao = Label.new()
    texto_licao.position = Vector2(27, 47)
    texto_licao.size = Vector2(300, 82)
    texto_licao.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    texto_licao.vertical_alignment = VERTICAL_ALIGNMENT_TOP
    texto_licao.clip_text = true
    texto_licao.add_theme_font_size_override("font_size", 13)
    texto_licao.add_theme_color_override("font_color", Color("#f4fff0"))
    texto_licao.add_theme_constant_override("line_spacing", 2)
    painel_licao.add_child(texto_licao)


func _criar_barra_controles() -> void:
    painel_controles = Panel.new()
    painel_controles.name = "BarraDicasControles"
    painel_controles.position = Vector2(250, 56)
    painel_controles.size = Vector2(610, 25)
    painel_controles.z_index = 80
    painel_controles.mouse_filter = Control.MOUSE_FILTER_IGNORE

    var estilo := StyleBoxFlat.new()
    estilo.bg_color = Color(0.015, 0.12, 0.09, 0.94)
    estilo.border_color = Color("#8fcf49")
    estilo.set_border_width_all(2)
    estilo.set_corner_radius_all(9)
    estilo.content_margin_left = 8
    estilo.content_margin_right = 8
    estilo.content_margin_top = 3
    estilo.content_margin_bottom = 3
    painel_controles.add_theme_stylebox_override("panel", estilo)
    add_child(painel_controles)

    var comandos := Label.new()
    comandos.text = "WASD MOVER  •  SHIFT CORRER  •  ESPAÇO SPRAY  •  E INTERAGIR  •  ESC PAUSAR"
    comandos.position = Vector2(6, 1)
    comandos.size = Vector2(598, 21)
    comandos.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    comandos.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    comandos.clip_text = true
    comandos.add_theme_font_size_override("font_size", 11)
    comandos.add_theme_color_override("font_color", Color("#f3ffec"))
    comandos.add_theme_color_override("font_outline_color", Color("#052c25"))
    comandos.add_theme_constant_override("outline_size", 2)
    painel_controles.add_child(comandos)

    # A dica de controles ajuda no início e sai sozinha após 10 segundos.
    _ocultar_controles_apos_dez_segundos()


func _ocultar_controles_apos_dez_segundos() -> void:
    await get_tree().create_timer(10.0, false).timeout
    if not is_instance_valid(painel_controles):
        return
    var desaparecer := create_tween()
    desaparecer.tween_property(painel_controles, "modulate:a", 0.0, 0.45)
    await desaparecer.finished
    if is_instance_valid(painel_controles):
        painel_controles.visible = false


func _montar_hud() -> void:
    # HUD limpo: vida, onda e pontos. Objetivo e contagem de alvos ficam ocultos.
    $MosquitosLabel.visible = false
    $MissaoLabel.visible = false
    for nome in ["OndaLabel", "HPLabel"]:
        var lbl: Label = get_node(nome)
        lbl.add_theme_color_override("font_color", Color("#ffffff"))
        lbl.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.85))
        lbl.add_theme_constant_override("shadow_offset_x", 2)
        lbl.add_theme_constant_override("shadow_offset_y", 2)
    $OndaLabel.position = Vector2(985, 13)
    $OndaLabel.size = Vector2(150, 32)
    $OndaLabel.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    $OndaLabel.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    $OndaLabel.add_theme_font_size_override("font_size", 18)
    $OndaLabel.add_theme_color_override("font_color", Color("#f1ffd9"))
    $OndaLabel.add_theme_color_override("font_outline_color", Color("#063b2b"))
    $OndaLabel.add_theme_constant_override("outline_size", 3)
    $OndaLabel.z_index = 41

    pontos_fundo = Panel.new()
    pontos_fundo.name = "PontosFundo"
    pontos_fundo.position = Vector2(864, 54)
    pontos_fundo.size = Vector2(274, 32)
    pontos_fundo.z_index = 40
    pontos_fundo.add_theme_stylebox_override("panel", _estilo_cartao_menu(Color("#ffbd45")))
    add_child(pontos_fundo)

    pontos_label = Label.new()
    pontos_label.name = "PontosLabel"
    pontos_label.position = Vector2(872, 57)
    pontos_label.size = Vector2(258, 25)
    pontos_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    pontos_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    pontos_label.add_theme_font_size_override("font_size", 15)
    pontos_label.add_theme_color_override("font_color", Color("#ffdf7b"))
    pontos_label.add_theme_color_override("font_outline_color", Color("#063b2b"))
    pontos_label.add_theme_constant_override("outline_size", 3)
    pontos_label.z_index = 42
    add_child(pontos_label)

    indicador_onda = Panel.new()
    indicador_onda.name = "IndicadorOndaFundo"
    indicador_onda.position = Vector2(980, 8)
    indicador_onda.size = Vector2(160, 42)
    indicador_onda.z_index = 40
    indicador_onda.add_theme_stylebox_override("panel", _estilo_cartao_menu(Color("#ffbd45")))
    add_child(indicador_onda)

    # O aviso antigo era apenas um Label central; o novo cartão usa animação e hierarquia visual.
    $OndaMensagemLabel.visible = false

    _criar_cartao_transicao_onda()
    _criar_cartao_licao()
    _criar_barra_controles()
    $BarraHP.position = Vector2(67, 17)
    $BarraHP.size = Vector2(180, 20)
    $HPLabel.position = Vector2(25, 12)
    $HPLabel.size = Vector2(40, 26)
    $HPLabel.text = "HP"
    $BarraHP.show_percentage = false

    barra_chefe = ProgressBar.new()
    barra_chefe.name = "BarraChefe"
    barra_chefe.position = Vector2(875, 82)
    barra_chefe.size = Vector2(245, 13)
    barra_chefe.max_value = 30
    barra_chefe.value = 30
    barra_chefe.visible = false
    add_child(barra_chefe)
    label_chefe = Label.new()
    label_chefe.name = "LabelChefe"
    label_chefe.position = Vector2(875, 58)
    label_chefe.size = Vector2(245, 21)
    label_chefe.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    label_chefe.add_theme_font_size_override("font_size", 16)
    label_chefe.add_theme_color_override("font_color", Color("#ffffff"))
    label_chefe.visible = false
    add_child(label_chefe)

    var aviso := Label.new()
    aviso.name = "MensagemLabel"
    aviso.visible = false
    aviso.position = Vector2(320, 565)
    aviso.size = Vector2(800, 34)
    aviso.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    aviso.clip_text = true
    aviso.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    aviso.add_theme_font_size_override("font_size", 17)
    aviso.add_theme_color_override("font_color", Color("#fff3b0"))
    aviso.add_theme_color_override("font_shadow_color", Color.BLACK)
    aviso.add_theme_constant_override("shadow_offset_x", 2)
    aviso.add_theme_constant_override("shadow_offset_y", 2)
    aviso.mouse_filter = Control.MOUSE_FILTER_IGNORE
    add_child(aviso)
