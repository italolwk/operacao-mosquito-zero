extends Control

func _ready() -> void:
    _aplicar_configuracoes_salvas()
    OMZAudio.play_menu_music()
    for botao in [$AreaJogar, $AreaInformacoes, $AreaConfiguracoes, $AreaSair]:
        _preparar_area_clicavel(botao)
    _preparar_botao_creditos($AreaCreditos)

func _preparar_area_clicavel(botao: Button) -> void:
    botao.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
    botao.focus_mode = Control.FOCUS_NONE
    botao.mouse_entered.connect(func(): OMZAudio.play_sfx("botao", -12.0))
    botao.add_theme_stylebox_override("normal", _area_style(Color(0, 0, 0, 0)))
    # O botão da arte já tem seu próprio contorno. No hover, apenas ilumina suavemente,
    # sem desenhar uma segunda moldura retangular fora do centro da arte.
    botao.add_theme_stylebox_override("hover", _area_style(Color(0, 0, 0, 0)))
    botao.add_theme_stylebox_override("pressed", _area_style(Color(0.05, 0.35, 0.15, 0.18)))
    botao.add_theme_stylebox_override("focus", _area_style(Color(0, 0, 0, 0)))

func _area_style(fundo: Color) -> StyleBoxFlat:
    var estilo := StyleBoxFlat.new()
    estilo.bg_color = fundo
    estilo.border_color = Color(0, 0, 0, 0)
    estilo.set_border_width_all(0)
    estilo.set_corner_radius_all(0)
    return estilo

func _aplicar_configuracoes_salvas() -> void:
    var config := ConfigFile.new()
    if config.load("user://omz_config.cfg") != OK:
        return
    var fullscreen := bool(config.get_value("video", "fullscreen", false))
    DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN if fullscreen else DisplayServer.WINDOW_MODE_WINDOWED)
    var tamanhos := [Vector2i(1152, 648), Vector2i(1280, 720), Vector2i(1600, 900), Vector2i(1920, 1080)]
    var indice := clampi(int(config.get_value("video", "resolution", 0)), 0, 3)
    if not fullscreen:
        DisplayServer.window_set_size(tamanhos[indice])

func _on_botaojogar_pressed() -> void:
    OMZAudio.play_sfx("botao", -5.0)
    get_tree().change_scene_to_file("res://mapa.tscn")

func _on_botao_informacoes_pressed() -> void:
    OMZAudio.play_sfx("botao", -5.0)
    get_tree().change_scene_to_file("res://informacoes.tscn")

func _abrir_configuracoes() -> void:
    OMZAudio.play_sfx("botao", -5.0)
    get_tree().change_scene_to_file("res://configuracoes.tscn")

func _abrir_creditos() -> void:
    OMZAudio.play_sfx("botao", -5.0)
    get_tree().change_scene_to_file("res://creditos.tscn")

func _preparar_botao_creditos(botao: Button) -> void:
    botao.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
    botao.focus_mode = Control.FOCUS_NONE
    botao.add_theme_font_size_override("font_size", 17)
    botao.add_theme_color_override("font_color", Color("#f5ffe7"))
    botao.add_theme_color_override("font_hover_color", Color.WHITE)
    botao.mouse_entered.connect(func(): OMZAudio.play_sfx("botao", -12.0))

    var normal := StyleBoxFlat.new()
    normal.bg_color = Color("#075b36")
    normal.border_color = Color("#b6ff55")
    normal.set_border_width_all(3)
    normal.set_corner_radius_all(10)
    normal.shadow_color = Color(0, 0, 0, 0.45)
    normal.shadow_size = 5

    var hover := normal.duplicate() as StyleBoxFlat
    hover.bg_color = Color("#0b8a4a")
    hover.border_color = Color("#efff9b")

    var pressed := normal.duplicate() as StyleBoxFlat
    pressed.bg_color = Color("#034226")

    botao.add_theme_stylebox_override("normal", normal)
    botao.add_theme_stylebox_override("hover", hover)
    botao.add_theme_stylebox_override("pressed", pressed)
    botao.add_theme_stylebox_override("focus", normal)

func _sair() -> void:
    OMZAudio.play_sfx("botao", -5.0)
    get_tree().quit()
