extends Control

func _ready() -> void:
    _montar_tela()

func _montar_tela() -> void:
    var sombra := ColorRect.new()
    sombra.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    sombra.color = Color(0.005, 0.035, 0.03, 0.64)
    sombra.mouse_filter = Control.MOUSE_FILTER_IGNORE
    add_child(sombra)

    var cabecalho := Panel.new()
    cabecalho.position = Vector2(32, 18)
    cabecalho.size = Vector2(1088, 78)
    cabecalho.add_theme_stylebox_override("panel", _painel_style())
    add_child(cabecalho)

    var titulo := _rotulo("CRÉDITOS", 34, Color("#f1ffd9"), true)
    titulo.position = Vector2(32, 29)
    titulo.size = Vector2(1088, 52)
    titulo.add_theme_color_override("font_outline_color", Color("#063b2b"))
    titulo.add_theme_constant_override("outline_size", 5)
    add_child(titulo)

    var painel := PanelContainer.new()
    painel.position = Vector2(80, 108)
    painel.size = Vector2(992, 425)
    painel.add_theme_stylebox_override("panel", _painel_style())
    add_child(painel)

    var coluna := VBoxContainer.new()
    coluna.add_theme_constant_override("separation", 7)
    coluna.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    coluna.size_flags_vertical = Control.SIZE_EXPAND_FILL
    painel.add_child(coluna)

    coluna.add_child(_rotulo("EQUIPE DE DESENVOLVIMENTO", 20, Color("#ffbd45"), true))

    var equipe := HBoxContainer.new()
    equipe.add_theme_constant_override("separation", 28)
    equipe.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    coluna.add_child(equipe)

    var coluna_esquerda := VBoxContainer.new()
    coluna_esquerda.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    coluna_esquerda.add_theme_constant_override("separation", 5)
    equipe.add_child(coluna_esquerda)
    coluna_esquerda.add_child(_rotulo("Pedro Antonio Soares de Souza", 17, Color.WHITE, true))
    coluna_esquerda.add_child(_rotulo("Alessandro Marques", 17, Color.WHITE, true))
    coluna_esquerda.add_child(_rotulo("Igor Andre Viana Domingos", 17, Color.WHITE, true))

    var coluna_direita := VBoxContainer.new()
    coluna_direita.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    coluna_direita.add_theme_constant_override("separation", 5)
    equipe.add_child(coluna_direita)
    coluna_direita.add_child(_rotulo("Eduardo Jun", 17, Color.WHITE, true))
    coluna_direita.add_child(_rotulo("Cauã Santana Vieira", 17, Color.WHITE, true))
    coluna_direita.add_child(_rotulo("Italo Gomes Resende", 17, Color.WHITE, true))

    var divisor_equipe := HSeparator.new()
    coluna.add_child(divisor_equipe)

    coluna.add_child(_rotulo("PROFESSOR ORIENTADOR", 18, Color("#ffbd45"), true))
    coluna.add_child(_rotulo("João Roberto Ursino da Cruz", 18, Color.WHITE, true))

    var divisor_academico := HSeparator.new()
    coluna.add_child(divisor_academico)

    coluna.add_child(_rotulo("CIÊNCIA DA COMPUTAÇÃO  •  3º SEMESTRE", 17, Color("#eaffd1"), true))
    coluna.add_child(_rotulo("Universidade Cruzeiro do Sul", 17, Color.WHITE, true))

    var divisor_apoio := HSeparator.new()
    coluna.add_child(divisor_apoio)

    coluna.add_child(_rotulo("APOIO CRIATIVO E TÉCNICO", 16, Color("#ffbd45"), true))
    var apoio := _rotulo("Ferramentas de inteligência artificial foram utilizadas como apoio ao desenvolvimento e à criação de recursos visuais.", 14, Color("#d7f0d3"), true)
    apoio.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    coluna.add_child(apoio)

    var faixa_rodape := Panel.new()
    faixa_rodape.position = Vector2(300, 548)
    faixa_rodape.size = Vector2(552, 78)
    faixa_rodape.add_theme_stylebox_override("panel", _painel_style())
    add_child(faixa_rodape)

    var voltar := Button.new()
    voltar.text = "◀  VOLTAR AO MENU"
    voltar.position = Vector2(426, 560)
    voltar.size = Vector2(300, 54)
    _estilizar_botao(voltar, true)
    voltar.pressed.connect(_voltar_menu)
    add_child(voltar)

func _rotulo(texto: String, tamanho: int, cor: Color, centralizar: bool = false) -> Label:
    var label := Label.new()
    label.text = texto
    label.add_theme_font_size_override("font_size", tamanho)
    label.add_theme_color_override("font_color", cor)
    label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    if centralizar:
        label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    return label

func _voltar_menu() -> void:
    OMZAudio.play_sfx("botao", -5.0)
    get_tree().change_scene_to_file("res://main.tscn")

func _painel_style() -> StyleBoxFlat:
    var estilo := StyleBoxFlat.new()
    estilo.bg_color = Color(0.015, 0.12, 0.09, 0.96)
    estilo.border_color = Color("#b6ff55")
    estilo.set_border_width_all(5)
    estilo.set_corner_radius_all(18)
    estilo.shadow_color = Color(0, 0, 0, 0.58)
    estilo.shadow_size = 14
    estilo.content_margin_left = 28
    estilo.content_margin_right = 28
    estilo.content_margin_top = 18
    estilo.content_margin_bottom = 18
    return estilo

func _estilizar_botao(botao: Button, laranja: bool = false) -> void:
    botao.add_theme_font_size_override("font_size", 19)
    botao.add_theme_color_override("font_color", Color.WHITE)
    botao.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
    botao.focus_mode = Control.FOCUS_NONE
    botao.mouse_entered.connect(func(): OMZAudio.play_sfx("botao", -12.0))
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
    botao.add_theme_stylebox_override("normal", normal)
    botao.add_theme_stylebox_override("hover", hover)
    botao.add_theme_stylebox_override("pressed", normal)
    botao.add_theme_stylebox_override("focus", normal)
