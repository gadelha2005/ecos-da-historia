extends Node
## Teste do card I9: joga a fase 1904 montada do começo ao fim, sozinho.
## Entra na fase_1904.tscn real, força o boato (tensão inicial mais alta), conversa com os
## 6 moradores na ordem escolhendo a melhor resposta e espera o fim da fase levar ao hub
## com a Chave da Saúde. Roda com --headless (fecha sozinho e imprime APROVADO/REPROVADO).

const CENA_FASE: String = "res://scenes/fases/fase_1904.tscn"
const CENA_HUB: String = "res://scenes/hub/hub.tscn"
const LIMITE_SEGUNDOS: float = 120.0

var _pesos: Dictionary = {}
var _tempo: float = 0.0
var _ok: bool = true


func _ready() -> void:
	if get_tree().current_scene == self:
		# a cena de teste some na troca de cena: o teste roda numa cópia pendurada na raiz
		set_process(false)
		var executor: Node = (get_script() as GDScript).new()
		executor.name = "ExecutorI9"
		get_tree().root.add_child.call_deferred(executor)
		return
	_rodar.call_deferred()


func _process(delta: float) -> void:
	_tempo += delta
	# fecha caixas de texto e o card "Você sabia?" sozinho
	if Mensagem.esta_aberta():
		Mensagem._avancar.emit()
	for no in get_tree().root.get_children():
		if no is CardSaber:
			no.fechar()
	if _tempo > LIMITE_SEGUNDOS:
		_fim(false, "tempo esgotado")


func _rodar() -> void:
	GameState.reiniciar()
	GameState.nome_jogador = "Teste"
	DialogoManager.mostrar_fala = func(_t: String) -> void: pass
	DialogoManager.escolher = _escolher_melhor

	SceneManager.trocar_cena(CENA_FASE, "Spawn_Inicio")
	await _esperar_cena(CENA_FASE)
	var fase := get_tree().current_scene
	await get_tree().create_timer(0.5).timeout

	_checar(fase.get_node("Moradores").get_child_count() == 6, "6 moradores na fase")
	_checar(fase.get_node("Provas").get_child_count() == 4, "4 provas na trilha")
	_checar(fase.has_node("FiltroAntigo"), "filtro sépia na fase")

	# pega as provas pela trilha
	for prova in fase.get_node("Provas").get_children():
		prova.interagir(fase.jogador)
		await get_tree().create_timer(0.1).timeout
	_checar(GameState.provas.size() == 4, "4 provas coletadas")

	# o boato chega: as conversas passam a começar com tensão
	await fase.boato.disparar()
	_checar(DialogoManager.tensao_inicial > 0, "boato subiu a tensão inicial (%d)" % DialogoManager.tensao_inicial)

	for id in GameState.MORADORES:
		var morador: Morador = fase.get_node("Moradores/Morador_%s" % id)
		_guardar_pesos(morador.dialogo)
		fase.jogador.pode_mover = true
		var resultado: Array = []
		morador.conversa_terminou.connect(func(_id: String, ok: bool) -> void: resultado.append(ok), CONNECT_ONE_SHOT)
		morador.interagir(fase.jogador)  # com as escolhas automáticas a conversa pode acabar na hora
		while resultado.is_empty():
			await get_tree().process_frame
		_checar(resultado[0], "%s aprovado" % Morador.nome_de(id))
		if not resultado[0]:
			_fim(false, "conversa reprovada")
			return
		await get_tree().create_timer(0.1).timeout

	await _esperar_cena(CENA_HUB)
	_checar(GameState.tem_chave(GameState.FASE_1904), "Chave da Saúde recebida")
	_checar(GameState.portal_liberado(GameState.FASE_1973), "portal de 1973 liberado")
	_fim(_ok, "")


func _esperar_cena(caminho: String) -> void:
	while get_tree().current_scene == null or get_tree().current_scene.scene_file_path != caminho:
		await get_tree().process_frame


func _escolher_melhor(_pergunta: String, opcoes: Array[Dictionary]) -> int:
	var melhor := -1
	for i in opcoes.size():
		if not opcoes[i]["habilitada"]:
			continue
		if melhor == -1 or _pesos.get(opcoes[i]["texto"], 0) > _pesos.get(opcoes[melhor]["texto"], 0):
			melhor = i
	return melhor


func _guardar_pesos(caminho: String) -> void:
	_pesos.clear()
	var d := DialogoLoader.carregar(caminho)
	for no_id in d.nos:
		for op in d.nos[no_id].opcoes:
			_pesos[op.texto] = op.peso


func _checar(cond: bool, descricao: String) -> void:
	print("  [%s] %s" % ["ok" if cond else "FALHOU", descricao])
	_ok = _ok and cond


func _fim(aprovado: bool, motivo: String) -> void:
	set_process(false)
	print("I9: %s %s" % ["APROVADO" if aprovado else "REPROVADO", motivo])
	DialogoManager.mostrar_fala = DialogoManager._mostrar_fala_padrao
	DialogoManager.escolher = DialogoManager._escolher_padrao
	if DisplayServer.get_name() == "headless":
		get_tree().quit()
