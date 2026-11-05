extends Node

const CAMINHO_CONFIG := "user://omz_config.cfg"
const MUSICA_MENU: AudioStream = preload("res://assets/audio/musica_menu_original.wav")
const SONS: Dictionary = {
    "spray": preload("res://assets/audio/spray.wav"),
    "impacto": preload("res://assets/audio/impacto.wav"),
    "mosquito_derrotado": preload("res://assets/audio/mosquito_derrotado.wav"),
    "dano": preload("res://assets/audio/dano.wav"),
    "vida": preload("res://assets/audio/vida.wav"),
    "coleta": preload("res://assets/audio/coleta.wav"),
    "onda": preload("res://assets/audio/onda.wav"),
    "chefe": preload("res://assets/audio/chefe.wav"),
    "vitoria": preload("res://assets/audio/vitoria.wav"),
    "derrota": preload("res://assets/audio/derrota.wav"),
    "agua": preload("res://assets/audio/agua.wav"),
    "botao": preload("res://assets/audio/botao.wav")
}

var _players: Array[AudioStreamPlayer] = []
var _indice: int = 0
var _musica: AudioStreamPlayer

func _ready() -> void:
    _garantir_barramentos()
    _musica = AudioStreamPlayer.new()
    _musica.name = "MusicaMenu"
    _musica.bus = "Music"
    _musica.stream = MUSICA_MENU
    _musica.process_mode = Node.PROCESS_MODE_ALWAYS
    _musica.finished.connect(_repetir_musica)
    add_child(_musica)
    for i in range(10):
        var player := AudioStreamPlayer.new()
        player.name = "SFX_%02d" % i
        player.bus = "SFX"
        player.process_mode = Node.PROCESS_MODE_ALWAYS
        add_child(player)
        _players.append(player)
    aplicar_volumes_salvos()

func _garantir_barramentos() -> void:
    if AudioServer.get_bus_index("Music") < 0:
        AudioServer.add_bus(-1)
        AudioServer.set_bus_name(AudioServer.bus_count - 1, "Music")
        AudioServer.set_bus_send(AudioServer.bus_count - 1, "Master")
    if AudioServer.get_bus_index("SFX") < 0:
        AudioServer.add_bus(-1)
        AudioServer.set_bus_name(AudioServer.bus_count - 1, "SFX")
        AudioServer.set_bus_send(AudioServer.bus_count - 1, "Master")

func _repetir_musica() -> void:
    if is_instance_valid(_musica) and _musica.stream == MUSICA_MENU:
        _musica.play()

func play_menu_music() -> void:
    if is_instance_valid(_musica) and not _musica.playing:
        _musica.play()

func stop_music() -> void:
    if is_instance_valid(_musica):
        _musica.stop()

func play_sfx(nome: String, volume_db: float = 0.0) -> void:
    if not SONS.has(nome) or _players.is_empty():
        return
    var player: AudioStreamPlayer = _players[_indice]
    _indice = (_indice + 1) % _players.size()
    player.stop()
    player.stream = SONS[nome] as AudioStream
    player.volume_db = volume_db
    player.pitch_scale = randf_range(0.96, 1.04) if nome in ["spray", "impacto", "coleta", "botao"] else 1.0
    player.play()

func aplicar_volumes_salvos() -> void:
    var config := ConfigFile.new()
    config.load(CAMINHO_CONFIG)
    var legado := float(config.get_value("audio", "master", 80.0))
    set_music_volume(float(config.get_value("audio", "music", legado)))
    set_sfx_volume(float(config.get_value("audio", "sfx", legado)))

func set_music_volume(valor: float) -> void:
    _definir_volume_barramento("Music", valor)

func set_sfx_volume(valor: float) -> void:
    _definir_volume_barramento("SFX", valor)

func _definir_volume_barramento(nome: String, valor: float) -> void:
    var indice := AudioServer.get_bus_index(nome)
    if indice >= 0:
        AudioServer.set_bus_volume_db(indice, linear_to_db(maxf(valor / 100.0, 0.001)))
        AudioServer.set_bus_mute(indice, valor <= 0.0)
