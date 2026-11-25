extends Node
## Teste dos cards L1 a L10: joga a fase 1979 montada, sozinho.
## Confere as regras da mesa de acordo (L6), entra pelo portal verde do hub, fala com o professor,
## pega as 4 provas, confere a ordem alternada (L3/L4), faz as máquinas ligarem (L7) até a
## negociação romper (N3.R), refaz, leva um acordo ruim à mesa (reinicia), refaz de novo,
## fecha um acordo bom e volta ao hub com a Chave do Meio Ambiente (L9).
## Roda com --headless (fecha sozinho e imprime APROVADO/REPROVADO).

const CENA_FASE: String = "res://scenes/fases/fase_1979.tscn"
const CENA_HUB: String = "res://scenes/hub/hub.tscn"
const LIMITE_SEGUNDOS: float = 240.0

var _pesos: Dictionary = {}
var _tempo: float = 0.0
var _ok: bool = true


func _ready() -> void:
	if get_tree().current_scene == self:
		set_process(false)
		var executor: Node = (get_script() as GDScript).new()
		executor.name = "ExecutorL10"
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
	_testar_regras_mesa()

	GameState.reiniciar()
	GameState.nome_jogador = "Teste"
	GameState.intro_vista = true
	GameState.moradores_concluidos = GameState.MORADORES.size()
	for f in [GameState.FASE_1904, GameState.FASE_1973]:
		GameState.dar_chave(f)
		GameState.encaixar_chave(f)
	DialogoManager.mostrar_fala = func(_t: String) -> void: pass
	DialogoManager.escolher = _escolher_melhor

	SceneManager.trocar_cena(CENA_HUB, "Spawn_Portal1973")
	await _esperar_cena(CENA_HUB)
	await get_tree().create_timer(0.5).timeout
	var portal: Portal = get_tree().current_scene.get_node("Portais/Portal1979")
	_checar(portal.cena_destino == CENA_FASE, "portal verde aponta para fase_1979.tscn")
	_checar(GameState.portal_liberado(GameState.FASE_1979), "portal de 1979 liberado")

	SceneManager.trocar_cena(CENA_FASE, "Spawn_Inicio")
	await _esperar_cena(CENA_FASE)
	await get_tree().create_timer(0.5).timeout
	var fase := get_tree().current_scene
	_checar(get_tree().get_nodes_in_group("moradores").size() == 7, "professor + 6 pessoas na fase")
	_checar(fase.get_node("Provas").get_child_count() == 4, "4 provas pelo mapa")
	var arte: Morador = fase.get_node("Moradores/Morador_jovem")
	_checar(arte.sprite.sprite_frames.resource_path.ends_with("fase1979/morador_jovem.tres"), "arte de 1979 carregada (L8a)")

	await _conversar_professor(fase)
	for prova in fase.get_node("Provas").get_children():
		prova.interagir(fase.jogador)
		await get_tree().create_timer(0.1).timeout
	_checar(GameState.provas.size() == 4, "4 provas coletadas")
	_checar(not fase.get_node("Moradores/Morador_engenheiro").e_a_vez(), "engenheiro espera a Dona Rita")

	# L7: as máquinas ligam e a tensão passa para a conversa seguinte
	var maquinas: MaquinasLigando = fase.maquinas
	fase.jogador.pode_mover = true
	maquinas._agendar(0.2)
	await maquinas.maquinas_ligaram
	_checar(GameState.tensao_fase == 10 and DialogoManager.tensao_inicial == 10, "máquinas subiram a tensão da fase para 10")
	var inicio: Array = []
	DialogoManager.tensao_mudou.connect(func(v: int) -> void: inicio.append(v), CONNECT_ONE_SHOT)
	if not await _conversar(fase, "dona_rita"):
		return
	_checar(not inicio.is_empty() and inicio[0] == 10, "conversa começou com a tensão que já estava na fase")
	_checar(int(GameState.confianca_lado["comunidade"]) > 0, "confiança da comunidade subiu (L2)")
	_checar(fase.get_node("Moradores/Morador_engenheiro").e_a_vez(), "agora é a vez do engenheiro (alternando)")

	# N3.R: tensão no máximo → a negociação rompe e a fase reinicia
	await get_tree().create_timer(0.2).timeout
	fase.jogador.pode_mover = true
	maquinas.aumento = 100
	maquinas._agendar(0.2)
	await _esperar_reinicio(fase)
	fase = get_tree().current_scene
	_checar(GameState.tentativas[GameState.FASE_1979] == 1, "máquinas no máximo romperam a negociação")
	_checar(GameState.npcs_concluidos[GameState.FASE_1979] == 0 and GameState.tensao_fase == 0, "fase voltou ao começo")
	_checar(GameState.provas.size() == 4, "provas continuam com o jogador")

	# acordo ruim: derrubar tudo → a comunidade sai da mesa
	await _conversar_professor(fase)
	if not await _conversar_todos(fase):
		return
	print("  confiança depois das conversas: ", GameState.confianca_lado)
	await _mandar_acordo(fase, ["derrubar", "desenho"])
	await _esperar_reinicio(fase)
	fase = get_tree().current_scene
	_checar(GameState.tentativas[GameState.FASE_1979] == 2, "acordo ruim reiniciou a fase")

	await _conversar_professor(fase)
	if not await _conversar_todos(fase):
		return
	await _mandar_acordo(fase, ["lagoa", "casas", "desenho", "empregos"])

	await _esperar_cena(CENA_HUB)
	_checar(GameState.tem_chave(GameState.FASE_1979), "Chave do Meio Ambiente recebida")
	_checar(GameState.portal_liberado(GameState.FASE_1982), "portal de 1982 liberado")
	var limite := _tempo + 15.0
	while not GameState.chaves_encaixadas[GameState.FASE_1979] and _tempo < limite:
		await get_tree().process_frame
	_checar(GameState.cor_zona(GameState.FASE_1979) == 1.0, "chave encaixada e zona da natureza com cor")
	_fim(_ok, "")


func _testar_regras_mesa() -> void:
	var r := MesaAcordo.carregar_regras()
	var conf := {"comunidade": 60, "empreendimento": 60}
	var bom := MesaAcordo.avaliar(["lagoa", "casas", "desenho", "empregos"], conf, 0, r)
	_checar(bom["aprovado"], "L6: acordo em que os dois lados cedem é aprovado (c=%d)" % bom["c"])
	var so_um := MesaAcordo.avaliar(["lagoa", "casas", "compensar", "embargar"], conf, 0, r)
	_checar(not so_um["aprovado"] and so_um["motivo"] == "empreendimento", "L6: acordo de um lado só reprova (maximin)")
	var quente := MesaAcordo.avaliar(["derrubar", "embargar"], conf, 10, r)
	_checar(not quente["aprovado"] and quente["motivo"] == "tensao", "L6: duas propostas extremas estouram a tensão")
	var poucas := MesaAcordo.avaliar(["lagoa"], conf, 0, r)
	_checar(poucas["motivo"] == "poucas", "L6: precisa de pelo menos 2 propostas")


func _conversar_professor(fase: Node) -> void:
	var professor: Comissao = fase.get_node("Moradores/Professor")
	fase.jogador.pode_mover = true
	await professor.interagir(fase.jogador)
	_checar(professor.apresentou, "professor apresentou a disputa")


func _conversar(fase: Node, id: String) -> bool:
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


func _conversar_todos(fase: Node) -> bool:
	for id in GameState.SEQUENCIA[GameState.FASE_1979]:
		if not await _conversar(fase, id):
			return false
	_checar(GameState.todos_concluidos(GameState.FASE_1979), "6 pessoas ouvidas, alternando os lados")
	return true


func _mandar_acordo(fase: Node, ids: Array) -> void:
	var professor: Comissao = fase.get_node("Moradores/Professor")
	fase.jogador.pode_mover = true
	professor.interagir(fase.jogador)
	var mesa: MesaAcordo = null
	while mesa == null:
		await get_tree().process_frame
		for no in fase.get_children():
			if no is MesaAcordo:
				mesa = no
	for id in ids:
		mesa.alternar(id)
	mesa.confirmar()


func _esperar_reinicio(antiga: Node) -> void:
	while get_tree().current_scene == antiga or get_tree().current_scene == null \
			or get_tree().current_scene.scene_file_path != CENA_FASE:
		await get_tree().process_frame
	await get_tree().create_timer(0.5).timeout


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
	print("L10: %s %s" % ["APROVADO" if aprovado else "REPROVADO", motivo])
	DialogoManager.mostrar_fala = DialogoManager._mostrar_fala_padrao
	DialogoManager.escolher = DialogoManager._escolher_padrao
	if DisplayServer.get_name() == "headless":
		get_tree().quit()
