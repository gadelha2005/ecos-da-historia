extends Node
## Teste dos cards L0, M1 a M5, M8 e M9: joga a fase 1973 montada, sozinho.
## Confere as regras da planta (M5), fala com a comissão, pega as amostras, conversa com
## os 5 defensores na ordem, recusa uma planta concentrada (a fase reinicia, N2.R), refaz
## tudo, aprova uma planta equilibrada e volta ao hub com a Chave da Cultura.
## Roda com --headless (fecha sozinho e imprime APROVADO/REPROVADO).

const CENA_FASE: String = "res://scenes/fases/fase_1973.tscn"
const CENA_HUB: String = "res://scenes/hub/hub.tscn"
const LIMITE_SEGUNDOS: float = 180.0

var _pesos: Dictionary = {}
var _tempo: float = 0.0
var _ok: bool = true


func _ready() -> void:
	if get_tree().current_scene == self:
		set_process(false)
		var executor: Node = (get_script() as GDScript).new()
		executor.name = "ExecutorM9"
		get_tree().root.add_child.call_deferred(executor)
		return
	_rodar.call_deferred()


func _process(delta: float) -> void:
	_tempo += delta
	if Mensagem.esta_aberta():
		Mensagem._avancar.emit()
	for no in get_tree().root.get_children():
		if no is CardSaber:
			no.fechar()
	if _tempo > LIMITE_SEGUNDOS:
		_fim(false, "tempo esgotado")


func _rodar() -> void:
	_testar_regras_planta()

	GameState.reiniciar()
	GameState.nome_jogador = "Teste"
	GameState.intro_vista = true
	GameState.dar_chave(GameState.FASE_1904)
	GameState.encaixar_chave(GameState.FASE_1904)
	DialogoManager.mostrar_fala = func(_t: String) -> void: pass
	DialogoManager.escolher = _escolher_melhor

	# o portal de 1973 do hub leva à fase real
	SceneManager.trocar_cena(CENA_HUB, "Spawn_Portal1904")
	await _esperar_cena(CENA_HUB)
	await get_tree().create_timer(0.5).timeout
	var portal: Portal = get_tree().current_scene.get_node("Portais/Portal1973")
	_checar(portal.cena_destino == CENA_FASE, "portal de 1973 aponta para fase_1973.tscn")
	_checar(GameState.portal_liberado(GameState.FASE_1973), "portal de 1973 liberado")

	SceneManager.trocar_cena(CENA_FASE, "Spawn_Inicio")
	await _esperar_cena(CENA_FASE)
	await get_tree().create_timer(0.5).timeout
	var fase := get_tree().current_scene
	_checar(fase.get_node("Moradores").get_child_count() == 6, "comissão + 5 defensores na fase")
	_checar(fase.get_node("Amostras").get_child_count() == 4, "4 amostras pelo campus")

	await _conversar_comissao(fase)
	for prova in fase.get_node("Amostras").get_children():
		prova.interagir(fase.jogador)
		await get_tree().create_timer(0.1).timeout
	_checar(GameState.provas.size() == 4, "4 amostras coletadas")

	# fora de ordem: o patrocinador ainda não conversa
	var patrocinador: Morador = fase.get_node("Moradores/Morador_patrocinador")
	_checar(not patrocinador.e_a_vez(), "patrocinador espera a vez dele")

	if not await _conversar_todos(fase):
		return
	_checar(GameState.todos_concluidos(GameState.FASE_1973), "5 defensores de acordo")
	print("  satisfação depois das conversas: ", GameState.satisfacao_grupos)

	# 1ª planta: tudo para a pintura → a comissão pede para refazer (N2.R)
	await _mandar_planta(fase, {"pintura": 10})
	await get_tree().create_timer(0.3).timeout
	await _esperar_cena(CENA_FASE)
	await get_tree().create_timer(0.5).timeout
	fase = get_tree().current_scene
	_checar(GameState.npcs_concluidos[GameState.FASE_1973] == 0, "planta concentrada reiniciou a fase")
	_checar(GameState.tentativas[GameState.FASE_1973] == 1, "tentativa contada")
	_checar(GameState.provas.size() == 4, "amostras continuam com o jogador")

	await _conversar_comissao(fase)
	if not await _conversar_todos(fase):
		return
	await _mandar_planta(fase, {"renda": 2, "cordel": 2, "teatro": 2, "pintura": 2, "patrocinador": 2})

	await _esperar_cena(CENA_HUB)
	_checar(GameState.tem_chave(GameState.FASE_1973), "Chave da Cultura recebida")
	_checar(GameState.portal_liberado(GameState.FASE_1979), "portal de 1979 liberado")
	var limite := _tempo + 15.0
	while not GameState.chaves_encaixadas[GameState.FASE_1973] and _tempo < limite:
		await get_tree().process_frame
	_checar(GameState.cor_zona(GameState.FASE_1973) == 1.0, "chave encaixada e zona da Cultura com cor")
	_fim(_ok, "")


func _testar_regras_planta() -> void:
	var r := PlantaMostra.carregar_regras()
	var boa := {"renda": 75, "cordel": 75, "teatro": 75, "pintura": 75, "patrocinador": 70}
	var eq := PlantaMostra.avaliar({"renda": 2, "cordel": 2, "teatro": 2, "pintura": 2, "patrocinador": 2}, boa, r)
	_checar(eq["aprovado"], "M5: plano equilibrado aprovado (c=%.0f)" % eq["c"])
	var um := PlantaMostra.avaliar({"pintura": 10}, boa, r)
	_checar(not um["aprovado"] and um["motivo"] == "concentrada", "M5: tudo num grupo só reprova")
	var triste := boa.duplicate()
	triste["patrocinador"] = 50
	var ins := PlantaMostra.avaliar({"renda": 3, "cordel": 3, "teatro": 2, "pintura": 2}, triste, r)
	_checar(not ins["aprovado"] and ins["motivo"] == "insatisfeito", "M5: grupo muito insatisfeito reprova")


func _conversar_comissao(fase: Node) -> void:
	var comissao: Comissao = fase.get_node("Moradores/Comissao")
	fase.jogador.pode_mover = true
	await comissao.interagir(fase.jogador)
	_checar(comissao.apresentou, "comissão apresentou a Mostra")


func _conversar_todos(fase: Node) -> bool:
	for id in GameState.SEQUENCIA[GameState.FASE_1973]:
		var morador: Morador = fase.get_node("Moradores/Morador_%s" % id)
		_guardar_pesos(morador.dialogo)
		fase.jogador.pode_mover = true
		var resultado: Array = []
		morador.conversa_terminou.connect(func(_id: String, ok: bool) -> void: resultado.append(ok), CONNECT_ONE_SHOT)
		morador.interagir(fase.jogador)
		while resultado.is_empty():
			await get_tree().process_frame
		_checar(resultado[0], "%s aprovado" % Morador.nome_de(id))
		if not resultado[0]:
			_fim(false, "conversa reprovada")
			return false
		await get_tree().create_timer(0.1).timeout
	return true


func _mandar_planta(fase: Node, plano: Dictionary) -> void:
	var comissao: Comissao = fase.get_node("Moradores/Comissao")
	fase.jogador.pode_mover = true
	comissao.interagir(fase.jogador)
	var planta: PlantaMostra = null
	while planta == null:
		await get_tree().process_frame
		for no in fase.get_children():
			if no is PlantaMostra:
				planta = no
	for g in plano:
		for i in plano[g]:
			planta.mudar(g, 1)
	planta.confirmar()


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
	print("M9: %s %s" % ["APROVADO" if aprovado else "REPROVADO", motivo])
	DialogoManager.mostrar_fala = DialogoManager._mostrar_fala_padrao
	DialogoManager.escolher = DialogoManager._escolher_padrao
	if DisplayServer.get_name() == "headless":
		get_tree().quit()
