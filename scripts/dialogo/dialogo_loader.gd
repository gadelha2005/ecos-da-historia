class_name DialogoLoader
extends RefCounted

const TIPOS := {
	"empatia": OpcaoDialogo.Tipo.EMPATIA,
	"fato": OpcaoDialogo.Tipo.FATO,
	"autoridade": OpcaoDialogo.Tipo.AUTORIDADE,
	"provas": OpcaoDialogo.Tipo.PROVAS,
}


static func carregar(caminho: String) -> Dialogo:
	if not FileAccess.file_exists(caminho):
		push_error("Diálogo não encontrado: %s" % caminho)
		return null

	var json := JSON.new()
	var erro := json.parse(FileAccess.get_file_as_string(caminho))
	if erro != OK:
		push_error("JSON inválido em %s (linha %d): %s" % [caminho, json.get_error_line(), json.get_error_message()])
		return null

	var dados: Variant = json.data
	if typeof(dados) != TYPE_DICTIONARY:
		push_error("%s: a raiz do JSON precisa ser um objeto { ... }" % caminho)
		return null

	var dialogo := Dialogo.new()
	dialogo.inicio = str(dados.get("inicio", ""))
	dialogo.dica = str(dados.get("dica", ""))
	for item in dados.get("nos", []):
		var no := _criar_no(item)
		dialogo.nos[no.id] = no

	var problemas := _validar(dialogo)
	for p in problemas:
		push_error("%s: %s" % [caminho, p])
	return dialogo


static func _criar_no(item: Dictionary) -> NoDialogo:
	var no := NoDialogo.new()
	no.id = str(item.get("id", ""))
	no.fala = str(item.get("fala", ""))
	no.final = bool(item.get("final", false))
	for o in item.get("opcoes", []):
		var op := OpcaoDialogo.new()
		op.texto = str(o.get("texto", ""))
		op.tipo = TIPOS.get(str(o.get("tipo", "empatia")), OpcaoDialogo.Tipo.EMPATIA)
		op.peso = int(o.get("peso", 0))
		op.tensao_delta = int(o.get("tensao", 0))
		op.destino = str(o.get("destino", ""))
		op.exige_prova = str(o.get("exige_prova", ""))
		no.opcoes.append(op)
	return no


# Devolve a lista de problemas encontrados (vazia = tudo certo).
static func _validar(dialogo: Dialogo) -> Array[String]:
	var problemas: Array[String] = []
	if not dialogo.nos.has(dialogo.inicio):
		problemas.append("nó inicial '%s' não existe" % dialogo.inicio)
	for id in dialogo.nos:
		var no: NoDialogo = dialogo.nos[id]
		if no.id == "":
			problemas.append("há um nó sem id")
		if not no.final and no.opcoes.is_empty():
			problemas.append("nó '%s' não é final e não tem opções (beco sem saída)" % id)
		for op in no.opcoes:
			if op.destino != "" and not dialogo.nos.has(op.destino):
				problemas.append("nó '%s' aponta para '%s', que não existe" % [id, op.destino])
	return problemas
