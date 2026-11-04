extends Area2D


func interagir(jogador: Player) -> void:
	jogador.pode_mover = false
	var chaves := GameState.total_chaves()
	if chaves >= GameState.TOTAL_FASES:
		await _mostrar(["A porta se abre."])
	else:
		await _mostrar(["Faltam %d chaves." % (GameState.TOTAL_FASES - chaves)])
	jogador.pode_mover = true


func _unhandled_input(event: InputEvent) -> void:
	# atalho de debug: F9 dá todas as chaves (só em build de debug)
	if OS.is_debug_build() and event is InputEventKey and event.pressed and event.keycode == KEY_F9:
		for i in GameState.TOTAL_FASES:
			GameState.dar_chave(i)
		print("Debug: todas as chaves liberadas")


func _mostrar(linhas: Array[String]) -> void:
	var mensagem := get_node_or_null("/root/Mensagem")
	if mensagem:
		await mensagem.mostrar(linhas)
	else:
		print("\n".join(linhas))
