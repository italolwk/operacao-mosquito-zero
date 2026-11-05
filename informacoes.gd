extends Control

const TOPICOS := [
    {"nome": "O JOGO", "texto": "Proteja a comunidade: elimine os mosquitos e, na missão final, retire a água do pneu. Durante as ondas, recolha objetos que acumulam água para ganhar pontos extras. A coleta é opcional."},
    {"nome": "DENGUE", "texto": "A dengue é uma doença causada por vírus e transmitida pela picada da fêmea infectada do Aedes aegypti. O mosquito também pode transmitir zika e chikungunya. Não existe transmissão direta de pessoa para pessoa."},
    {"nome": "PREVENÇÃO", "texto": "• Mantenha caixas-d’água e tonéis bem tampados.\n• Esvazie e lave recipientes que acumulam chuva.\n• Coloque areia até a borda dos pratinhos de plantas.\n• Guarde pneus em local coberto e protegido da chuva.\n• Limpe calhas, ralos e bandejas de geladeira.\n• Descarte corretamente garrafas, latas e embalagens."},
    {"nome": "OBJETOS COLETÁVEIS", "texto": "Vasos com pratinhos, baldes, bacias, garrafas PET, latas e caixas abertas podem acumular água. Durante a partida, aproxime-se de um objeto e pressione E para recolhê-lo e ganhar pontos extras. A coleta é opcional: as ondas avançam quando todos os mosquitos são eliminados."},
    {"nome": "CICLO DO MOSQUITO", "texto": "O Aedes aegypti passa por quatro fases: ovo, larva, pupa e adulto. As três primeiras acontecem na água. Em condições favoráveis, o desenvolvimento pode ser rápido. Eliminar recipientes com água interrompe o ciclo antes que surjam novos adultos."},
    {"nome": "CURIOSIDADES", "texto": "• Os ovos podem resistir por meses em locais secos.\n• A fêmea deposita ovos nas paredes internas de recipientes, perto da linha da água.\n• Pequenas tampinhas e embalagens também podem acumular água.\n• O mosquito costuma ter atividade durante o dia, especialmente no início da manhã e no fim da tarde."}
]

var titulo_conteudo: Label
var texto_conteudo: Label
var controles_box: HBoxContainer

func _ready() -> void:
    _montar_tela()
    _selecionar_topico("O JOGO")

func _montar_tela() -> void:
    var sombra := ColorRect.new()
    sombra.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    sombra.color = Color(0.005, 0.035, 0.03, 0.52)
    sombra.mouse_filter = Control.MOUSE_FILTER_IGNORE
    add_child(sombra)

    var faixa_cabecalho := Panel.new()
    faixa_cabecalho.position = Vector2(32, 8)
    faixa_cabecalho.size = Vector2(1088, 62)
    faixa_cabecalho.add_theme_stylebox_override("panel", _painel_style())
    add_child(faixa_cabecalho)

    var cabecalho := Label.new()
    cabecalho.text = "GUIA DA OPERAÇÃO"
    cabecalho.position = Vector2(96, 16)
    cabecalho.size = Vector2(960, 48)
    cabecalho.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    cabecalho.add_theme_font_size_override("font_size", 34)
    cabecalho.add_theme_color_override("font_color", Color("#f1ffd9"))
    cabecalho.add_theme_color_override("font_outline_color", Color("#063b2b"))
    cabecalho.add_theme_constant_override("outline_size", 5)
    add_child(cabecalho)

    var painel := Panel.new()
    painel.position = Vector2(32, 78)
    painel.size = Vector2(1088, 480)
    painel.add_theme_stylebox_override("panel", _painel_style())
    add_child(painel)

    var layout := HBoxContainer.new()
    layout.position = Vector2(18, 18)
    layout.size = Vector2(1052, 444)
    layout.add_theme_constant_override("separation", 16)
    painel.add_child(layout)

    var menu_topicos := VBoxContainer.new()
    menu_topicos.custom_minimum_size = Vector2(255, 0)
    menu_topicos.add_theme_constant_override("separation", 5)
    layout.add_child(menu_topicos)

    var subtitulo := Label.new()
    subtitulo.text = "APRENDA E PREVINA"
    subtitulo.custom_minimum_size = Vector2(245, 38)
    subtitulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    subtitulo.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    subtitulo.add_theme_font_size_override("font_size", 20)
    subtitulo.add_theme_color_override("font_color", Color("#ffbd45"))
    menu_topicos.add_child(subtitulo)

    for item in TOPICOS:
        var botao := Button.new()
        botao.text = item["nome"]
        botao.custom_minimum_size = Vector2(245, 44)
        botao.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        _estilizar_botao(botao)
        botao.pressed.connect(_selecionar_topico.bind(item["nome"]))
        menu_topicos.add_child(botao)

    var controles_botao := Button.new()
    controles_botao.text = "CONTROLES"
    controles_botao.custom_minimum_size = Vector2(245, 44)
    _estilizar_botao(controles_botao)
    controles_botao.pressed.connect(_selecionar_topico.bind("CONTROLES"))
    menu_topicos.add_child(controles_botao)

    var conteudo_painel := PanelContainer.new()
    conteudo_painel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    conteudo_painel.size_flags_vertical = Control.SIZE_EXPAND_FILL
    conteudo_painel.add_theme_stylebox_override("panel", _painel_interno_style())
    layout.add_child(conteudo_painel)

    var coluna := VBoxContainer.new()
    coluna.add_theme_constant_override("separation", 18)
    conteudo_painel.add_child(coluna)

    titulo_conteudo = Label.new()
    titulo_conteudo.custom_minimum_size = Vector2(0, 48)
    titulo_conteudo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    titulo_conteudo.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    titulo_conteudo.add_theme_font_size_override("font_size", 27)
    titulo_conteudo.add_theme_color_override("font_color", Color("#ffbd45"))
    coluna.add_child(titulo_conteudo)

    texto_conteudo = Label.new()
    texto_conteudo.size_flags_vertical = Control.SIZE_EXPAND_FILL
    texto_conteudo.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    texto_conteudo.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    texto_conteudo.add_theme_font_size_override("font_size", 21)
    texto_conteudo.add_theme_color_override("font_color", Color("#f3fff0"))
    texto_conteudo.add_theme_constant_override("line_spacing", 7)
    coluna.add_child(texto_conteudo)

    controles_box = HBoxContainer.new()
    controles_box.size_flags_vertical = Control.SIZE_EXPAND_FILL
    controles_box.add_theme_constant_override("separation", 22)
    coluna.add_child(controles_box)

    var faixa_rodape := Panel.new()
    faixa_rodape.position = Vector2(310, 566)
    faixa_rodape.size = Vector2(532, 74)
    faixa_rodape.add_theme_stylebox_override("panel", _painel_style())
    add_child(faixa_rodape)

    var voltar := Button.new()
    voltar.text = "◀  VOLTAR AO MENU"
    voltar.position = Vector2(426, 578)
    voltar.size = Vector2(300, 54)
    _estilizar_botao(voltar, true)
    voltar.pressed.connect(func(): get_tree().change_scene_to_file("res://main.tscn"))
    add_child(voltar)

func _selecionar_topico(nome: String) -> void:
    titulo_conteudo.text = nome
    texto_conteudo.visible = nome != "CONTROLES"
    controles_box.visible = nome == "CONTROLES"
    if nome == "CONTROLES":
        for filho in controles_box.get_children():
            filho.queue_free()
        _montar_coluna_controles("MOVIMENTAÇÃO E AÇÕES", [
            "WASD / SETAS    Movimentar",
            "SHIFT                 Correr",
            "ESPAÇO              Usar o spray",
            "E                         Coletar / interagir",
            "ESC                    Pausar a partida"
        ])
        _montar_coluna_controles("OBJETIVO E DICAS", [
            "Elimine todos os mosquitos para avançar de onda.",
            "Colete baldes, garrafas, latas e recipientes com água para ganhar pontos.",
            "Os objetos colecionáveis são opcionais.",
            "Na onda final, derrote o Mosquito-mãe, pegue o balde e esvazie o pneu."
        ])
    else:
        for item in TOPICOS:
            if item["nome"] == nome:
                texto_conteudo.text = item["texto"]
                break

func _montar_coluna_controles(cabecalho: String, linhas: Array) -> void:
    var coluna := VBoxContainer.new()
    coluna.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    coluna.add_theme_constant_override("separation", 13)
    controles_box.add_child(coluna)
    var titulo := Label.new()
    titulo.text = cabecalho
    titulo.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    titulo.add_theme_font_size_override("font_size", 19)
    titulo.add_theme_color_override("font_color", Color("#ffbd45"))
    coluna.add_child(titulo)
    for linha in linhas:
        var label := Label.new()
        label.text = linha
        label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
        label.add_theme_font_size_override("font_size", 17)
        label.add_theme_color_override("font_color", Color("#f3fff0"))
        label.custom_minimum_size.y = 30
        coluna.add_child(label)

func _painel_style() -> StyleBoxFlat:
    var estilo := StyleBoxFlat.new()
    estilo.bg_color = Color(0.015, 0.12, 0.09, 1.0)
    estilo.border_color = Color("#b6ff55")
    estilo.set_border_width_all(5)
    estilo.set_corner_radius_all(18)
    estilo.shadow_color = Color(0, 0, 0, 0.58)
    estilo.shadow_size = 14
    return estilo

func _painel_interno_style() -> StyleBoxFlat:
    var estilo := StyleBoxFlat.new()
    estilo.bg_color = Color("#064536")
    estilo.border_color = Color("#f2a52e")
    estilo.set_border_width_all(3)
    estilo.set_corner_radius_all(12)
    estilo.content_margin_left = 22
    estilo.content_margin_right = 22
    estilo.content_margin_top = 15
    estilo.content_margin_bottom = 15
    return estilo

func _estilizar_botao(botao: Button, laranja: bool = false) -> void:
    botao.add_theme_font_size_override("font_size", 17)
    botao.add_theme_color_override("font_color", Color.WHITE)
    botao.add_theme_color_override("font_hover_color", Color("#fff0a8"))
    botao.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
    var normal := StyleBoxFlat.new()
    normal.bg_color = Color("#087b43") if not laranja else Color("#c76b12")
    normal.border_color = Color("#b6ff55") if not laranja else Color("#ffe17b")
    normal.set_border_width_all(4)
    normal.set_corner_radius_all(11)
    normal.shadow_color = Color(0, 0, 0, 0.4)
    normal.shadow_size = 5
    var hover := normal.duplicate() as StyleBoxFlat
    hover.bg_color = Color("#149d56") if not laranja else Color("#ed8a1e")
    hover.border_color = Color("#efff9b")
    var pressed := normal.duplicate() as StyleBoxFlat
    pressed.bg_color = Color("#075b36") if not laranja else Color("#a9500c")
    botao.add_theme_stylebox_override("normal", normal)
    botao.add_theme_stylebox_override("hover", hover)
    botao.add_theme_stylebox_override("pressed", pressed)
    botao.add_theme_stylebox_override("focus", normal)
