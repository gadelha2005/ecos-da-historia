extends Control
## Teste do card K11. Simule o progresso, "feche o jogo" (zera o GameState) e use
## Continuar: o progresso volta do user://save.json e o jogo vai para o hub.

@onready var estado: Label = %Estado
@onready var continuar: Button = %Continuar


func _ready() -> void:
	%PegarChave.pressed.connect(_pegar_chave)
	%Zerar.pressed.connect(_zerar)
	continuar.pressed.connect(Save.continuar)
	%Apagar.pressed.connect(_apagar)
	Save.salvo.connect(_atualizar)
	%PegarChave.grab_focus()
	_atualizar()


func _process(_delta: float) -> void:
	estado.text = "Chaves: %s\nEncaixadas na porta: %s\nNome: %s   ·   Intro vista: %s\nSave em disco: %s" % [
		str(GameState.chaves), str(GameState.chaves_encaixadas), GameState.nome_jogador,
		"sim" if GameState.intro_vista else "não", "sim" if Save.existe() else "não"]


func _pegar_chave() -> void:
	# simula a volta da fase: a próxima chave é pega e encaixada (o save acontece sozinho)
	var fase := GameState.chaves.find(false)
	if fase == -1:
		return
	if GameState.nome_jogador == "":
		GameState.nome_jogador = "Teste"
	GameState.intro_vista = true
	GameState.dar_chave(fase)
	GameState.encaixar_chave(fase)


func _zerar() -> void:
	GameState.reiniciar()  # é como fechar e abrir o jogo: memória limpa, o arquivo continua


func _apagar() -> void:
	Save.apagar()
	_atualizar()


func _atualizar() -> void:
	continuar.visible = Save.existe()
