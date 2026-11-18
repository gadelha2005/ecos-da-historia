extends Node2D
## Teste do K6: terminal de treino do menu de escolhas.
## Jogando (F6): ande até o terminal azul e aperte o botão de interagir.
## Headless (--headless): valida o tutorial.json no H5 e joga o terminal 4 vezes
## (Empatia, Fato, Autoridade e Provas), conferindo que Provas fica desabilitado
## sem a prova e que o GameState não muda. Fecha com código 0/1.

const CAMINHO: String = "res://data/dialogos/tutorial.json"
const TIPOS: Array[String] = ["empatia", "fato", "autoridade", "provas"]

@onready var jogador: Player = $Player
@onready var terminal: TerminalTutorial = $TerminalTutorial
@onready var hud: HudDialogo = $HudDialogo

var _falas: Array[String] = []
var _menus: Array = []      # cada chamada do menu: Array[Dictionary] de opções
var _respostas: Array = []  # índices a devolver, em ordem
var _travado_no_menu := true  # o jogador ficou parado em todos os menus?


func _ready() -> void:
	DialogoManager.tensao_mudou.connect(hud.definir_tensao)
	DialogoManager.confianca_mudou.connect(hud.definir_confianca)
	if DisplayServer.get_name() == "headless":
		await _teste_automatico()
	else:
		print("K6: ande até o terminal e interaja. Dá para repetir quantas vezes quiser.")
		terminal.treino_terminou.connect(func(r: Dictionary) -> void: print("Treino terminou: ", r))


func _teste_automatico() -> void:
	var ok := true
	GameState.reiniciar()

	var d := DialogoLoader.carregar(CAMINHO)
	ok = _checar(d != null, "tutorial.json carrega") and ok
	var v := ValidadorGrafo.analisar(d)
	ok = _checar(v["ok"], "passa no validador H5 (S_min %d, S_max %d)" % [v["s_min"], v["s_max"]]) and ok
	for p in v["problemas"]:
		print("    PROBLEMA: ", p)
	ok = _checar(d.nos.size() >= 4 and d.nos.size() <= 6, "4 a 6 nós (%d)" % d.nos.size()) and ok
	var tipos_inicio: Array = []
	for op in d.nos[d.inicio].opcoes:
		tipos_inicio.append(String(OpcaoDialogo.Tipo.keys()[op.tipo]).to_lower())
	ok = _checar(tipos_inicio == TIPOS, "pergunta inicial com os 4 tipos") and ok

	DialogoManager.mostrar_fala = func(texto: String) -> void:
		_falas.append(texto)
	DialogoManager.escolher = _escolher_automatico

	var antes := _foto_game_state()

	# Empatia, Fato e Autoridade. Na primeira rodada tenta apertar Provas antes
	# (desabilitado): o menu precisa perguntar de novo.
	var rotulos := ["[Empatia]", "[Fato]", "[Autoridade]"]
	for i in 3:
		_respostas = ([3, i] if i == 0 else [i]) + [0]
		var r := await _jogar()
		var primeiro: Array = _menus[0]
		ok = _checar(primeiro.size() == 4 and not primeiro[3]["habilitada"], "Provas desabilitado sem a prova") and ok
		if i == 0:
			ok = _checar(_menus.size() == 3, "clicar no Provas desabilitado não avança") and ok
		ok = _checar(_falou(rotulos[i]), "%s explica o tipo" % TIPOS[i]) and ok
		ok = _checar(not r["falhou"] and _falas[-1].begins_with("Fim do treino"), "%s chega ao fim" % TIPOS[i]) and ok
		ok = _checar(_travado_no_menu, "jogador travado durante a conversa") and ok
		ok = _checar(jogador.pode_mover, "jogador destravado depois do treino") and ok

	ok = _checar(_foto_game_state() == antes, "GameState igual depois de 3 treinos") and ok

	# Provas: com a prova de treino o botão acende. A prova é tirada logo depois.
	GameState.dar_prova("prova_treino")
	_respostas = [3, 0]
	var rp := await _jogar()
	GameState.provas.erase("prova_treino")
	ok = _checar(_menus[0][3]["habilitada"], "Provas habilitado com a prova") and ok
	ok = _checar(_falou("[Provas]") and not rp["falhou"], "provas explica o tipo e termina") and ok
	ok = _checar(_foto_game_state() == antes, "GameState igual no fim (sem chave, sem dica, sem reinício)") and ok

	print("K6: %s" % ("APROVADO" if ok else "REPROVADO"))
	get_tree().quit(0 if ok else 1)


func _jogar() -> Dictionary:
	_falas.clear()
	_menus.clear()
	_travado_no_menu = true
	var resultado := {}
	var guardar := func(r: Dictionary) -> void: resultado.merge(r)
	terminal.treino_terminou.connect(guardar, CONNECT_ONE_SHOT)
	await terminal.interagir(jogador)
	return resultado


func _escolher_automatico(_pergunta: String, opcoes: Array[Dictionary]) -> int:
	_menus.append(opcoes.duplicate(true))
	_travado_no_menu = _travado_no_menu and not jogador.pode_mover
	var i: int = _respostas.pop_front() if not _respostas.is_empty() else 0
	print("  [menu] %s -> %s" % [opcoes.map(func(o): return "%s%s" % [o["tipo"], "" if o["habilitada"] else "(off)"]), opcoes[i]["tipo"]])
	return i


func _falou(trecho: String) -> bool:
	for f in _falas:
		if trecho in f:
			return true
	return false


func _foto_game_state() -> String:
	return var_to_str({
		"chaves": GameState.chaves, "encaixadas": GameState.chaves_encaixadas,
		"tentativas": GameState.tentativas, "pontuacao": GameState.pontuacao,
		"moradores": GameState.moradores_concluidos, "provas": GameState.provas,
		"dicas": GameState.dicas, "intro": GameState.intro_vista,
	})


func _checar(cond: bool, descricao: String) -> bool:
	print("  [%s] %s" % ["ok" if cond else "FALHOU", descricao])
	return cond


func _exit_tree() -> void:
	DialogoManager.mostrar_fala = DialogoManager._mostrar_fala_padrao
	DialogoManager.escolher = DialogoManager._escolher_padrao
