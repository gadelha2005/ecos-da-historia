class_name ValidadorGrafo
extends RefCounted


# Devolve: ok, problemas, s_min, s_max, ordem (ordem topológica dos nós alcançáveis).
static func analisar(d: Dialogo) -> Dictionary:
	var problemas: Array[String] = []

	if not d.nos.has(d.inicio):
		problemas.append("nó inicial '%s' não existe" % d.inicio)
		return _resultado(problemas, 0, 0, [])

	# 1) BFS a partir do início
	var alcancaveis: Dictionary = {}  # id -> true
	var fila: Array[String] = [d.inicio]
	alcancaveis[d.inicio] = true
	while not fila.is_empty():
		var atual: String = fila.pop_front()
		for dest in _destinos(d.nos[atual]):
			if d.nos.has(dest) and not alcancaveis.has(dest):
				alcancaveis[dest] = true
				fila.append(dest)

	for id in d.nos:
		if not alcancaveis.has(id):
			problemas.append("nó '%s' é inalcançável (órfão)" % id)

	var tem_final := false
	for id in alcancaveis:
		var no: NoDialogo = d.nos[id]
		if no.final:
			tem_final = true
	if not tem_final:
		problemas.append("nenhum nó final é alcançável")

	# 2) Kahn: ordenação topológica e detecção de ciclo
	var grau: Dictionary = {}  # id -> quantas arestas chegam
	for id in alcancaveis:
		grau[id] = 0
	for id in alcancaveis:
		for dest in _destinos(d.nos[id]):
			if grau.has(dest):
				grau[dest] += 1

	var pronta: Array[String] = []
	for id in grau:
		if grau[id] == 0:
			pronta.append(id)

	var ordem: Array[String] = []
	while not pronta.is_empty():
		var atual: String = pronta.pop_front()
		ordem.append(atual)
		for dest in _destinos(d.nos[atual]):
			if grau.has(dest):
				grau[dest] -= 1
				if grau[dest] == 0:
					pronta.append(dest)

	if ordem.size() < alcancaveis.size():
		problemas.append("o grafo tem ciclo (a conversa pode nunca terminar)")
		return _resultado(problemas, 0, 0, [])

	# 3) Programação dinâmica na ordem topológica reversa
	var pontos_max: Dictionary = {}
	var pontos_min: Dictionary = {}
	for i in range(ordem.size() - 1, -1, -1):
		var id := ordem[i]
		var no: NoDialogo = d.nos[id]
		if no.final or no.opcoes.is_empty():
			pontos_max[id] = 0
			pontos_min[id] = 0
			continue
		var melhor := -1000000000
		var pior := 1000000000
		for op in no.opcoes:
			var resto_max := 0
			var resto_min := 0
			if op.destino != "" and pontos_max.has(op.destino):
				resto_max = pontos_max[op.destino]
				resto_min = pontos_min[op.destino]
			melhor = maxi(melhor, op.peso + resto_max)
			pior = mini(pior, op.peso + resto_min)
		pontos_max[id] = melhor
		pontos_min[id] = pior

	return _resultado(problemas, pontos_min[d.inicio], pontos_max[d.inicio], ordem)


# c = 100 * (S - S_min) / (S_max - S_min), limitado entre 0 e 100.
static func nota(s: int, s_min: int, s_max: int) -> float:
	if s_max == s_min:
		return 100.0
	return clampf(100.0 * (s - s_min) / float(s_max - s_min), 0.0, 100.0)


# Destinos de um nó (nó final não segue adiante).
static func _destinos(no: NoDialogo) -> Array[String]:
	var lista: Array[String] = []
	if no.final:
		return lista
	for op in no.opcoes:
		if op.destino != "":
			lista.append(op.destino)
	return lista


static func _resultado(problemas: Array[String], s_min: int, s_max: int, ordem: Array[String]) -> Dictionary:
	return {
		"ok": problemas.is_empty(),
		"problemas": problemas,
		"s_min": s_min,
		"s_max": s_max,
		"ordem": ordem,
	}
