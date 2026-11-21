extends Node
## [K11] Salvar e carregar o progresso (autoload "Save").
## Grava em user://save.json os campos do GameState listados em CAMPOS, sem editar o
## game_state.gd (lê e escreve os campos de fora). Salva sozinho sempre que uma chave
## nova é encaixada na porta (GameState.chaves_encaixadas).
##
## Para o botão "Continuar" do menu inicial (F1):
##   botao_continuar.visible = Save.existe()
##   botao_continuar.pressed.connect(Save.continuar)

signal salvo
signal carregado

const ARQUIVO := "user://save.json"
const VERSAO := 1
const CENA_HUB := "res://scenes/hub/hub.tscn"
const CAMPOS: Array[String] = [
	"nome_jogador", "aparencia", "chaves", "chaves_encaixadas", "tentativas", "pontuacao", "intro_vista",
]

## Confere de quanto em quanto tempo (s) se uma chave nova foi encaixada.
const INTERVALO_VERIFICACAO := 0.25

var _encaixadas_antes: int = 0


func _ready() -> void:
	_encaixadas_antes = _contar_encaixadas()
	var relogio := Timer.new()
	relogio.wait_time = INTERVALO_VERIFICACAO
	relogio.autostart = true
	relogio.timeout.connect(_verificar_encaixe)
	add_child(relogio)


func existe() -> bool:
	return FileAccess.file_exists(ARQUIVO)


func salvar() -> bool:
	var dados := {"versao": VERSAO}
	for campo in CAMPOS:
		dados[campo] = GameState.get(campo)
	var arquivo := FileAccess.open(ARQUIVO, FileAccess.WRITE)
	if arquivo == null:
		push_warning("Save: não foi possível gravar %s (%s)" % [ARQUIVO, error_string(FileAccess.get_open_error())])
		return false
	arquivo.store_string(JSON.stringify(dados, "\t"))
	arquivo.close()
	salvo.emit()
	return true


## Lê o save e copia os campos para o GameState. Devolve false se não houver save válido.
func carregar() -> bool:
	if not existe():
		return false
	var lido: Variant = JSON.parse_string(FileAccess.get_file_as_string(ARQUIVO))
	if not (lido is Dictionary):
		push_warning("Save: arquivo inválido, ignorado.")
		return false
	var dados: Dictionary = lido
	for campo in CAMPOS:
		if dados.has(campo):
			_copiar(campo, dados[campo])
	_encaixadas_antes = _contar_encaixadas()
	carregado.emit()
	return true


## Carrega o save e volta ao hub (ação do botão "Continuar").
func continuar() -> void:
	if carregar():
		SceneManager.trocar_cena(CENA_HUB, "Spawn_Inicio")


func apagar() -> void:
	if existe():
		DirAccess.remove_absolute(ProjectSettings.globalize_path(ARQUIVO))


func _verificar_encaixe() -> void:
	var agora := _contar_encaixadas()
	if agora > _encaixadas_antes:
		salvar()
	_encaixadas_antes = agora


func _contar_encaixadas() -> int:
	return GameState.chaves_encaixadas.count(true)


## Copia um valor do JSON para o GameState mantendo o tipo do campo
## (os arrays do GameState são tipados: Array[bool], Array[int], Array[float]).
func _copiar(campo: String, valor: Variant) -> void:
	var atual: Variant = GameState.get(campo)
	if atual is Array and valor is Array:
		var destino: Array = atual
		for i in mini(destino.size(), valor.size()):
			match typeof(destino[i]):
				TYPE_BOOL: destino[i] = bool(valor[i])
				TYPE_INT: destino[i] = int(valor[i])
				TYPE_FLOAT: destino[i] = float(valor[i])
				_: destino[i] = valor[i]
	elif atual is bool:
		GameState.set(campo, bool(valor))
	elif atual is int:
		GameState.set(campo, int(valor))
	elif atual is float:
		GameState.set(campo, float(valor))
	else:
		GameState.set(campo, str(valor))
