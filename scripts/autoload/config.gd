extends Node
## [F5] Configurações do jogador (autoload "Config").
## Guarda em user://configuracoes.cfg e aplica tudo assim que o jogo abre.

const CAMINHO: String = "user://configuracoes.cfg"

var volume: int = 80          # 0 a 100 (volume geral, barramento Master)
var tela_cheia: bool = false


func _ready() -> void:
	carregar()
	aplicar()


func carregar() -> void:
	var arquivo := ConfigFile.new()
	if arquivo.load(CAMINHO) != OK:
		return  # primeira vez abrindo o jogo: fica com os valores padrão
	volume = clampi(int(arquivo.get_value("audio", "volume", volume)), 0, 100)
	tela_cheia = bool(arquivo.get_value("video", "tela_cheia", tela_cheia))


func salvar() -> void:
	var arquivo := ConfigFile.new()
	arquivo.set_value("audio", "volume", volume)
	arquivo.set_value("video", "tela_cheia", tela_cheia)
	arquivo.save(CAMINHO)


func aplicar() -> void:
	definir_volume(volume)
	definir_tela_cheia(tela_cheia)


func definir_volume(valor: int) -> void:
	volume = clampi(valor, 0, 100)
	var bus := AudioServer.get_bus_index("Master")
	AudioServer.set_bus_mute(bus, volume == 0)
	AudioServer.set_bus_volume_db(bus, linear_to_db(volume / 100.0))


func definir_tela_cheia(ligada: bool) -> void:
	tela_cheia = ligada
	if ligada:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	elif DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
