class_name TerminalTutorial
extends Area2D
## [K6] Terminal de treino do hub (N0.6): projeta um holograma de teste para o
## jogador aprender o menu de escolhas. Só roda a conversa: NÃO chama o
## AvaliadorConversa, então não dá chave, não guarda dica e não reinicia nada.
## Pode repetir quantas vezes quiser.

signal treino_terminou(resultado: Dictionary)

const CAMINHO_DIALOGO: String = "res://data/dialogos/tutorial.json"

var _ocupado: bool = false


func interagir(jogador: Player) -> void:
	if _ocupado:
		return
	_ocupado = true
	if jogador != null:
		jogador.pode_mover = false
	var resultado: Dictionary = await DialogoManager.iniciar(CAMINHO_DIALOGO)
	if jogador != null and is_instance_valid(jogador):
		jogador.pode_mover = true
	_ocupado = false
	treino_terminou.emit(resultado)
