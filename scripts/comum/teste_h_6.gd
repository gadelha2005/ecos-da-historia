extends Node

const CAMINHO: String = "res://data/dialogos/exemplo.json"


func _ready() -> void:
	AvaliadorConversa.ao_reiniciar = func() -> void:
		print(">> (a fase seria reiniciada agora)")
	GameState.reiniciar()
	print("Concluídos antes: ", GameState.moradores_concluidos)

	var r: Dictionary = await DialogoManager.iniciar(CAMINHO)
	var ok := AvaliadorConversa.avaliar("inacia", CAMINHO, r)

	print("Aprovado: ", ok)
	print("Concluídos depois: ", GameState.moradores_concluidos)
	print("Tentativas da fase 1904: ", GameState.tentativas[GameState.FASE_1904])
	print("Dica guardada: ", GameState.dicas.get("inacia", "(nenhuma)"))
	print("Dona Maria liberada? ", GameState.morador_liberado("dona_maria"))
