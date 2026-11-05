extends Node2D

var ciclo: float = 0.0
var brilho_impacto: float = 0.0

func _process(delta: float) -> void:
    ciclo += delta * 18.0
    brilho_impacto = maxf(0.0, brilho_impacto - delta * 3.0)
    queue_redraw()

func _draw() -> void:
    var flap := sin(ciclo) * 3.0
    # Sombra suave e asas translúcidas com nervuras.
    draw_ellipse_custom(Vector2(0, 8), Vector2(13, 4), Color(0.02, 0.05, 0.06, 0.20))
    _asa(Vector2(-7, -9 + flap), -0.30)
    _asa(Vector2(7, -9 - flap), 0.30)
    # Pernas articuladas, com joelhos e anéis brancos típicos do Aedes.
    for lado in [-1.0, 1.0]:
        for i in range(3):
            var origem := Vector2(lado * 2.0, 0.0 + float(i) * 2.0)
            var joelho := Vector2(lado * (11.0 + float(i) * 2.0), 8.0 + float(i) * 2.0)
            var ponta := Vector2(lado * (18.0 + float(i) * 2.0), 18.0 + float(i) * 2.0)
            draw_line(origem, joelho, Color("#171c25"), 2.2, true)
            draw_line(joelho, ponta, Color("#171c25"), 2.0, true)
            draw_line(joelho.lerp(ponta, 0.35), joelho.lerp(ponta, 0.62), Color("#f4f1e8"), 2.2, true)
            draw_circle(joelho, 1.5, Color("#f4f1e8"))
    # Abdome escuro segmentado e tórax com marca clara em forma de lira estilizada.
    draw_ellipse_custom(Vector2(-1, 2), Vector2(6.0, 10.0), Color("#111722"))
    draw_ellipse_custom(Vector2(-1, -3), Vector2(5.0, 5.5), Color("#242c39"))
    for y in [-3.0, 1.0, 5.0, 9.0]:
        draw_line(Vector2(-5.0, y), Vector2(3.0, y), Color("#f0eee6"), 1.8, true)
    draw_line(Vector2(-3, -6), Vector2(0, -10), Color("#f4f1e8"), 1.4, true)
    draw_line(Vector2(0, -10), Vector2(3, -6), Color("#f4f1e8"), 1.4, true)
    # Cabeça simpática, olhos grandes e probóscide fina.
    draw_circle(Vector2(5, -8), 5.0, Color("#151b25"))
    draw_circle(Vector2(3.5, -9), 1.8, Color.WHITE)
    draw_circle(Vector2(6.5, -9), 1.8, Color.WHITE)
    draw_circle(Vector2(4, -9), 0.8, Color("#202a39"))
    draw_circle(Vector2(7, -9), 0.8, Color("#202a39"))
    draw_line(Vector2(9, -7), Vector2(17, -10), Color("#171c25"), 1.5, true)
    if brilho_impacto > 0.0:
        draw_circle(Vector2.ZERO, 22.0, Color(1.0, 0.55, 0.22, brilho_impacto * 0.25))

func _asa(pos: Vector2, inclinacao: float) -> void:
    var pontos := PackedVector2Array([
        pos + Vector2(-1, 0).rotated(inclinacao),
        pos + Vector2(9, -9).rotated(inclinacao),
        pos + Vector2(19, -7).rotated(inclinacao),
        pos + Vector2(14, 2).rotated(inclinacao),
        pos + Vector2(3, 4).rotated(inclinacao)
    ])
    draw_colored_polygon(pontos, Color(0.77, 0.91, 1.0, 0.72))
    draw_polyline(pontos, Color(0.93, 0.98, 1.0, 0.9), 1.0, true)
    draw_line(pos, pos + Vector2(15, -4).rotated(inclinacao), Color(0.91, 0.97, 1.0, 0.75), 0.8, true)

func draw_ellipse_custom(center: Vector2, radius: Vector2, cor: Color) -> void:
    var pontos := PackedVector2Array()
    for k in range(24):
        var theta: float = TAU * float(k) / 24.0
        pontos.append(center + Vector2(cos(theta) * radius.x, sin(theta) * radius.y))
    draw_colored_polygon(pontos, cor)
