class_name Comissao
extends Morador
## [M9] Comissão da Mostra (1973). Não entra na fila de conversas avaliadas:
## no começo apresenta o problema (comissao.json, N2.2) e, quando os 5 defensores
## estiverem de acordo, pede a planta final (N2.5) pelo sinal planta_pedida.

signal planta_pedida

## A comissão já se apresentou nesta visita à fase (volta a false a cada reinício).
var apresentou: bool = false


func e_a_vez() -> bool:
	return not apresentou or GameState.todos_concluidos(fase)


func ja_concluido() -> bool:
	return false


func interagir(jogador: Player) -> void:
	if _conversando:
		return
	_conversando = true
	jogador.pode_mover = false

	if GameState.todos_concluidos(fase):
		await _mostrar(["Todos foram ouvidos. Agora vamos montar a planta da Mostra juntos."], nome_de(morador_id))
		_conversando = false
		planta_pedida.emit()
		return  # quem devolve o movimento é a fase, depois da planta

	if ResourceLoader.exists(dialogo):
		await DialogoManager.iniciar(dialogo)
	apresentou = true
	if GameState.npcs_concluidos[fase] > 0:
		await _eco(["Continue a conversa com %s." % nome_de(_proximo_da_fila())])
	get_tree().call_group("moradores", "atualizar_indicador")

	_conversando = false
	if is_instance_valid(jogador):
		jogador.pode_mover = true
