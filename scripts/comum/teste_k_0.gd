extends Node


func _ready() -> void:
	GameState.reiniciar()
	var recebidas: Array[int] = []
	GameState.chave_recebida.connect(func(f: int) -> void: recebidas.append(f))

	assert(GameState.chave_pendente() == -1, "sem chave, nada pendente")

	GameState.dar_chave(0)
	assert(recebidas == [0], "dar_chave(0) emite o sinal uma vez")
	GameState.dar_chave(0)
	assert(recebidas == [0], "repetir a chave não emite de novo")
	assert(GameState.chave_pendente() == 0, "chave 0 pendente")
	assert(GameState.cor_zona(0) == 0.0, "zona ainda cinza")

	GameState.encaixar_chave(0)
	assert(GameState.chave_pendente() == -1, "depois de encaixar, nada pendente")
	assert(GameState.cor_zona(0) == 1.0, "zona colorida")
	assert(GameState.cor_zona(1) == 0.0, "as outras seguem cinza")

	GameState.intro_vista = true
	GameState.reiniciar()
	assert(not GameState.intro_vista and GameState.cor_zona(0) == 0.0, "reiniciar zera tudo")

	print("K0 OK")
