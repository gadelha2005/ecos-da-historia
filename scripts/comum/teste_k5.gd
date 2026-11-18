extends Node
## Teste do K5: confere o data/hub/falas_hub.json (formato e chaves) e se o
## HubEventos (K8) lê as falas dele. Roda headless e fecha com código 0/1.

const CAMINHO: String = "res://data/hub/falas_hub.json"


func _ready() -> void:
	var ok := true
	var texto := FileAccess.get_file_as_string(CAMINHO)
	var dados: Variant = JSON.parse_string(texto)
	ok = _checar(dados != null, "JSON.parse_string não devolve null") and ok
	ok = _checar(dados is Dictionary, "raiz é um objeto") and ok
	if not (dados is Dictionary):
		_fim(false)
		return

	var intro: Array = dados.get("intro", [])
	ok = _checar(intro.size() >= 6 and intro.size() <= 10, "intro com 6 a 10 linhas (%d)" % intro.size()) and ok
	ok = _checar("{nome}" in "\n".join(intro), "intro usa {nome}") and ok
	ok = _checar(_lista_de_textos(dados.get("hub")), "hub é uma lista de falas") and ok
	for grupo in ["volta", "portal_trancado"]:
		var d: Variant = dados.get(grupo)
		ok = _checar(d is Dictionary, "%s é um objeto" % grupo) and ok
		for fase in 4:
			var linhas: Variant = d.get(str(fase)) if d is Dictionary else null
			ok = _checar(_lista_de_textos(linhas), "%s[\"%d\"] tem falas" % [grupo, fase]) and ok
	var porta: Variant = dados.get("porta")
	ok = _checar(porta is Dictionary, "porta é um objeto") and ok
	if porta is Dictionary:
		ok = _checar(_lista_de_textos(porta.get("faltam")) and "{n}" in str(porta.get("faltam")), "porta.faltam usa {n}") and ok
		ok = _checar(_lista_de_textos(porta.get("abrindo")), "porta.abrindo tem falas") and ok

	# Integração com o K8: o HubEventos usa as falas do JSON no lugar das padrão.
	GameState.reiniciar()
	GameState.nome_jogador = "Ana"
	var eventos := HubEventos.new()
	eventos.auto_iniciar = false
	add_child(eventos)
	var linhas_intro: Array = eventos._linhas("intro")
	ok = _checar(linhas_intro.size() == intro.size(), "HubEventos leu a intro do JSON") and ok
	ok = _checar("Ana" in linhas_intro[0] and not "{nome}" in linhas_intro[0], "{nome} trocado pelo nome do jogador") and ok
	ok = _checar(eventos._linhas("volta", 0) == dados["volta"]["0"], "HubEventos leu volta[0]") and ok

	print("--- falas ---")
	for linha in linhas_intro + eventos._linhas("hub"):
		print("  ECO: ", linha)
	_fim(ok)


func _lista_de_textos(v: Variant) -> bool:
	if not (v is Array) or v.is_empty():
		return false
	for item in v:
		if not (item is String) or item.strip_edges() == "":
			return false
	return true


func _checar(cond: bool, descricao: String) -> bool:
	print("  [%s] %s" % ["ok" if cond else "FALHOU", descricao])
	return cond


func _fim(ok: bool) -> void:
	print("K5: %s" % ("APROVADO" if ok else "REPROVADO"))
	if DisplayServer.get_name() == "headless":
		get_tree().quit(0 if ok else 1)
