extends Control

const CAMINHO_CONFIG := "user://omz_config.cfg"
var config := ConfigFile.new()
var musica_slider: HSlider
var efeitos_slider: HSlider
var tela_cheia: CheckButton
var resolucao: OptionButton
var dica_status: Label
var valor_musica: Label
var valor_efeitos: Label

func _ready() -> void:
    config.load(CAMINHO_CONFIG)
    _montar_tela()
    _carregar_valores()

func _montar_tela() -> void:
    var sombra := ColorRect.new()
    sombra.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    sombra.color = Color(0.005, 0.035, 0.03, 0.52)
    sombra.mouse_filter = Control.MOUSE_FILTER_IGNORE
    add_child(sombra)

    var faixa_cabecalho := Panel.new()
    faixa_cabecalho.position = Vector2(32, 18)
    faixa_cabecalho.size = Vector2(1088, 82)
    faixa_cabecalho.add_theme_stylebox_override("panel", _painel_style())
    add_child(faixa_cabecalho)

    var cabecalho := Label.new()
    cabecalho.text = "⚙  CONFIGURAÇÕES"
    cabecalho.position = Vector2(270, 29)
    cabecalho.size = Vector2(612, 54)
    cabecalho.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    cabecalho.add_theme_font_size_override("font_size", 34)
    cabecalho.add_theme_color_override("font_color", Color("#f1ffd9"))
    cabecalho.add_theme_color_override("font_outline_color", Color("#063b2b"))
    cabecalho.add_theme_constant_override("outline_size", 5)
    add_child(cabecalho)

    var painel := PanelContainer.new()
    painel.position = Vector2(32, 100)
    painel.size = Vector2(1088, 425)
    painel.add_theme_stylebox_override("panel", _painel_style())
    add_child(painel)

    var coluna := VBoxContainer.new()
    coluna.add_theme_constant_override("separation", 18)
    painel.add_child(coluna)

    var audio_titulo := Label.new()
    audio_titulo.text = "ÁUDIO"
    audio_titulo.add_theme_font_size_override("font_size", 22)
    audio_titulo.add_theme_color_override("font_color", Color("#ffbd45"))
    coluna.add_child(audio_titulo)

    musica_slider = _criar_linha_volume(coluna, "Música de fundo", "music")
    efeitos_slider = _criar_linha_volume(coluna, "Efeitos sonoros", "sfx")

    var divisor := HSeparator.new()
    coluna.add_child(divisor)

    var video_titulo := Label.new()
    video_titulo.text = "VÍDEO"
    video_titulo.add_theme_font_size_override("font_size", 22)
    video_titulo.add_theme_color_override("font_color", Color("#ffbd45"))
    coluna.add_child(video_titulo)

    tela_cheia = CheckButton.new()
    tela_cheia.text = "Tela cheia"
    tela_cheia.add_theme_font_size_override("font_size", 19)
    tela_cheia.add_theme_color_override("font_color", Color.WHITE)
    tela_cheia.toggled.connect(_alterar_tela_cheia)
    coluna.add_child(tela_cheia)

    var resolucao_linha := HBoxContainer.new()
    resolucao_linha.add_theme_constant_override("separation", 18)
    coluna.add_child(resolucao_linha)

    var resolucao_label := Label.new()
    resolucao_label.text = "Resolução"
    resolucao_label.custom_minimum_size = Vector2(130, 40)
    resolucao_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    resolucao_label.add_theme_font_size_override("font_size", 18)
    resolucao_label.add_theme_color_override("font_color", Color.WHITE)
    resolucao_linha.add_child(resolucao_label)

    resolucao = OptionButton.new()
    resolucao.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    resolucao.custom_minimum_size = Vector2(0, 42)
    resolucao.add_item("1152 × 648 (padrão)", 0)
    resolucao.add_item("1280 × 720", 1)
    resolucao.add_item("1600 × 900", 2)
    resolucao.add_item("1920 × 1080", 3)
    resolucao.item_selected.connect(_alterar_resolucao)
    resolucao_linha.add_child(resolucao)

    dica_status = Label.new()
    dica_status.text = "As alterações são salvas automaticamente."
    dica_status.add_theme_font_size_override("font_size", 15)
    dica_status.add_theme_color_override("font_color", Color("#d7f0d3"))
    coluna.add_child(dica_status)

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

func _criar_linha_volume(pai: VBoxContainer, titulo: String, tipo: String) -> HSlider:
    var linha := HBoxContainer.new()
    linha.add_theme_constant_override("separation", 15)
    pai.add_child(linha)

    var label := Label.new()
    label.text = titulo
    label.custom_minimum_size = Vector2(170, 35)
    label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    label.add_theme_font_size_override("font_size", 18)
    label.add_theme_color_override("font_color", Color.WHITE)
    linha.add_child(label)

    var slider := HSlider.new()
    slider.min_value = 0
    slider.max_value = 100
    slider.step = 1
    slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    slider.custom_minimum_size = Vector2(260, 35)
    if tipo == "music":
        slider.value_changed.connect(_alterar_volume_musica)
    else:
        slider.value_changed.connect(_alterar_volume_efeitos)
    linha.add_child(slider)

    var valor_label := Label.new()
    valor_label.name = "ValorMusica" if tipo == "music" else "ValorEfeitos"
    valor_label.custom_minimum_size = Vector2(48, 35)
    valor_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    valor_label.add_theme_font_size_override("font_size", 17)
    valor_label.add_theme_color_override("font_color", Color("#eaffd1"))
    linha.add_child(valor_label)
    return slider

func _carregar_valores() -> void:
    var legado := float(config.get_value("audio", "master", 80.0))
    var musica := float(config.get_value("audio", "music", legado))
    var efeitos := float(config.get_value("audio", "sfx", legado))
    musica_slider.set_value_no_signal(musica)
    efeitos_slider.set_value_no_signal(efeitos)
    _atualizar_rotulos_volume(musica, efeitos)
    OMZAudio.set_music_volume(musica)
    OMZAudio.set_sfx_volume(efeitos)

    var fullscreen := bool(config.get_value("video", "fullscreen", false))
    tela_cheia.set_pressed_no_signal(fullscreen)
    _aplicar_tela_cheia(fullscreen)
    var indice := int(config.get_value("video", "resolution", 0))
    resolucao.select(clampi(indice, 0, 3))

func _atualizar_rotulos_volume(musica: float, efeitos: float) -> void:
    var painel := get_node_or_null("PanelContainer")
    if painel == null:
        return
    var valor_m := _buscar_rotulo("ValorMusica")
    var valor_e := _buscar_rotulo("ValorEfeitos")
    if valor_m: valor_m.text = str(int(musica)) + "%"
    if valor_e: valor_e.text = str(int(efeitos)) + "%"

func _buscar_rotulo(nome: String) -> Label:
    for no in find_children("*", "Label", true, false):
        if no.name == nome:
            return no as Label
    return null

func _alterar_volume_musica(valor: float) -> void:
    OMZAudio.set_music_volume(valor)
    config.set_value("audio", "music", valor)
    _atualizar_rotulos_volume(valor, efeitos_slider.value)
    _salvar()

func _alterar_volume_efeitos(valor: float) -> void:
    OMZAudio.set_sfx_volume(valor)
    config.set_value("audio", "sfx", valor)
    _atualizar_rotulos_volume(musica_slider.value, valor)
    _salvar()

func _alterar_tela_cheia(ativado: bool) -> void:
    _aplicar_tela_cheia(ativado)
    config.set_value("video", "fullscreen", ativado)
    _salvar()

func _aplicar_tela_cheia(ativado: bool) -> void:
    DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN if ativado else DisplayServer.WINDOW_MODE_WINDOWED)

func _alterar_resolucao(indice: int) -> void:
    var tamanhos := [Vector2i(1152, 648), Vector2i(1280, 720), Vector2i(1600, 900), Vector2i(1920, 1080)]
    config.set_value("video", "resolution", indice)
    if not tela_cheia.button_pressed:
        DisplayServer.window_set_size(tamanhos[indice])
    _salvar()

func _salvar() -> void:
    config.save(CAMINHO_CONFIG)
    dica_status.text = "Configurações salvas!"

func _voltar_menu() -> void:
    OMZAudio.play_sfx("botao", -5.0)
    get_tree().change_scene_to_file("res://main.tscn")

func _painel_style() -> StyleBoxFlat:
    var estilo := StyleBoxFlat.new()
    estilo.bg_color = Color(0.015, 0.12, 0.09, 1.0)
    estilo.border_color = Color("#b6ff55")
    estilo.set_border_width_all(5)
    estilo.set_corner_radius_all(18)
    estilo.shadow_color = Color(0, 0, 0, 0.58)
    estilo.shadow_size = 14
    estilo.content_margin_left = 28
    estilo.content_margin_right = 28
    estilo.content_margin_top = 24
    estilo.content_margin_bottom = 24
    return estilo

func _estilizar_botao(botao: Button, laranja: bool = false) -> void:
    botao.add_theme_font_size_override("font_size", 19)
    botao.add_theme_color_override("font_color", Color.WHITE)
    botao.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
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
