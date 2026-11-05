extends ColorRect

var agua_presente: bool = true
var animando_esvaziar: bool = false
var progresso_agua: float = 1.0
var brilho_agua: float = 0.0

func _ready() -> void:
    mouse_filter = Control.MOUSE_FILTER_IGNORE
    queue_redraw()

func _process(delta: float) -> void:
    brilho_agua += delta
    if agua_presente or animando_esvaziar:
        queue_redraw()

func esvaziar() -> void:
    if animando_esvaziar or not agua_presente:
        return
    animando_esvaziar = true
    var tween := create_tween()
    tween.tween_method(_definir_progresso, 1.0, 0.0, 2.15).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
    await tween.finished
    agua_presente = false
    animando_esvaziar = false
    queue_redraw()

func _definir_progresso(valor: float) -> void:
    progresso_agua = valor
    queue_redraw()

func _draw() -> void:
    var centro := size * 0.5
    # Sombra projetada.
    _desenhar_elipse(centro + Vector2(2, 7), Vector2(53, 39), Color(0.02, 0.04, 0.03, 0.28))
    # Borracha externa em camadas, com volume e bordas iluminadas.
    _desenhar_elipse(centro, Vector2(53, 39), Color("#10151b"))
    _desenhar_elipse(centro, Vector2(49, 35), Color("#30363b"))
    _desenhar_elipse(centro + Vector2(-1, -2), Vector2(44, 31), Color("#1b2228"))
    draw_arc(centro, 49.0, PI * 1.05, PI * 1.95, 48, Color("#73736e"), 2.0, true)
    draw_arc(centro, 43.0, 0.0, TAU, 48, Color("#090d12"), 3.0, true)
    # Blocos de banda de rodagem, rachaduras e pequenas manchas de desgaste.
    for i in range(18):
        var a: float = TAU * float(i) / 18.0
        var direcao := Vector2(cos(a), sin(a))
        var p1 := centro + direcao * Vector2(43.0, 31.0)
        var p2 := centro + direcao.rotated(0.12) * Vector2(50.0, 36.0)
        draw_line(p1, p2, Color("#555b5d"), 3.0, true)
        draw_line(p1 + Vector2(-2, 2), p2 + Vector2(-1, 2), Color("#171c21"), 1.4, true)
    for i in range(8):
        var x: float = -32.0 + float(i) * 9.0
        draw_line(centro + Vector2(x, -31), centro + Vector2(x + 3, -27), Color("#77746a", 0.72), 1.2, true)
    # Cavidade interna profunda.
    _desenhar_elipse(centro + Vector2(0, 1), Vector2(31, 22), Color("#080d12"))
    draw_arc(centro + Vector2(0, 1), 31.0, PI, TAU, 40, Color("#555d60"), 2.0, true)
    if agua_presente or animando_esvaziar:
        var largura: float = 27.0 * progresso_agua
        var altura: float = 17.0 * progresso_agua
        var agua_centro := centro + Vector2(0, 5)
        # Água azul-esverdeada escura com borda, profundidade e ondulações.
        _desenhar_elipse(agua_centro, Vector2(largura, altura), Color(0.035, 0.23, 0.31, 0.98))
        _desenhar_elipse(agua_centro + Vector2(-1, -2), Vector2(largura * 0.88, altura * 0.72), Color(0.08, 0.43, 0.54, 0.94))
        var ondulacao: float = sin(brilho_agua * 2.2) * 1.8
        draw_arc(agua_centro + Vector2(-2, -2 + ondulacao), maxf(4.0, largura * 0.72), PI * 1.08, PI * 1.86, 36, Color(0.68, 0.91, 0.94, 0.8), 1.7, true)
        draw_line(agua_centro + Vector2(-15, -8), agua_centro + Vector2(-5, -10 + ondulacao), Color(0.88, 0.98, 1.0, 0.9), 1.8, true)
        draw_line(agua_centro + Vector2(7, 2), agua_centro + Vector2(15, 0), Color(0.52, 0.82, 0.88, 0.7), 1.2, true)
        # Folhinhas pequenas ajudam a comunicar água acumulada.
        if progresso_agua > 0.55:
            _desenhar_elipse(agua_centro + Vector2(12, -5), Vector2(5, 2.2), Color("#7d9b4d"))
            draw_line(agua_centro + Vector2(8, -5), agua_centro + Vector2(16, -5), Color("#d4d5a0"), 1.0, true)

func _desenhar_elipse(center: Vector2, radius: Vector2, color: Color) -> void:
    var points := PackedVector2Array()
    for i in range(48):
        var angle := TAU * float(i) / 48.0
        points.append(center + Vector2(cos(angle) * radius.x, sin(angle) * radius.y))
    draw_colored_polygon(points, color)
