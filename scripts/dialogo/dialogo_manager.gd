extends Node

signal tensao_mudou(valor: int)
signal confianca_mudou(valor: int)
signal _tecla_escolhida(indice: int)  # uso interno (substituto do menu)

const LIMITE_TENSAO: int = 100
const CAMINHO_MENU: String = "res://scenes/ui/menu_escolhas.tscn"

var tensao: int = 0
var confianca: int = 50
var pontos: int = 0

# Apresentação trocável: func(texto: String) -> void  e  func(pergunta: String, opcoes: Array[Dictionary]) -> int
var mostrar_fala: Callable
var escolher: Callable

var _esperando_tecla: bool = false


func _ready() -> void:
	mostrar_fala = _mostrar_fala_padrao
	escolher = _escolher_padrao


# Roda uma conversa inteira. Devolve {"pontos", "falhou", "tensao"}.
func iniciar(caminho: String) -> Dictionary:
	var dialogo := DialogoLoader.carregar(caminho)
	if dialogo == null:
		return {"pontos": 0, "falhou": true, "tensao": tensao}

	pontos = 0
	_definir_tensao(0)
	_definir_confianca(50)

	var falhou := false
	var atual: String = dialogo.inicio
	while atual != "" and dialogo.nos.has(atual):
		var no: NoDialogo = dialogo.nos[atual]
		await mostrar_fala.call(no.fala)
		if no.final or no.opcoes.is_empty():
			break

		var opcoes := _montar_opcoes(no)
		var indice := -1
		while indice < 0 or indice >= opcoes.size() or not opcoes[indice]["habilitada"]:
			indice = await escolher.call("Como você responde?", opcoes)

		var op: OpcaoDialogo = no.opcoes[indice]
		pontos += op.peso
		_definir_confianca(confianca + op.peso * 5)
		_definir_tensao(tensao + op.tensao_delta)
		if tensao >= LIMITE_TENSAO:
			falhou = true
			break
		atual = op.destino

	return {"pontos": pontos, "falhou": falhou, "tensao": tensao}


# Lista de {"texto", "tipo", "habilitada"} para o menu (contrato do H1).
func _montar_opcoes(no: NoDialogo) -> Array[Dictionary]:
	var lista: Array[Dictionary] = []
	for op in no.opcoes:
		var libera: bool = op.exige_prova == "" or GameState.tem_prova(op.exige_prova)
		lista.append({
			"texto": op.texto,
			"tipo": String(OpcaoDialogo.Tipo.keys()[op.tipo]).to_lower(),
			"habilitada": libera,
		})
	# Proteção: se nenhuma opção está liberada, libera todas (evita travar a conversa).
	var alguma := false
	for o in lista:
		if o["habilitada"]:
			alguma = true
	if not alguma:
		push_warning("Nó '%s' sem nenhuma opção liberada; liberando todas." % no.id)
		for o in lista:
			o["habilitada"] = true
	return lista


func _definir_tensao(valor: int) -> void:
	tensao = clampi(valor, 0, 100)
	tensao_mudou.emit(tensao)


func _definir_confianca(valor: int) -> void:
	confianca = clampi(valor, 0, 100)
	confianca_mudou.emit(confianca)


# --- Apresentação padrão: usa o F3 e o H1 se existirem; senão, console. ---

func _mostrar_fala_padrao(texto: String) -> void:
	var mensagem := get_node_or_null("/root/Mensagem")
	if mensagem != null:
		await mensagem.mostrar([texto])
	else:
		print("[fala] ", texto)
		await get_tree().create_timer(0.2).timeout


func _escolher_padrao(pergunta: String, opcoes: Array[Dictionary]) -> int:
	if ResourceLoader.exists(CAMINHO_MENU):
		var menu = load(CAMINHO_MENU).instantiate()
		add_child(menu)
		var resultado: int = await menu.escolher(pergunta, opcoes)
		menu.queue_free()
		return resultado

	# Substituto de console enquanto o H1 não existe.
	print(pergunta)
	for i in opcoes.size():
		var o: Dictionary = opcoes[i]
		var aviso := "" if o["habilitada"] else "  (indisponível)"
		print("  [%d] (%s) %s%s" % [i + 1, o["tipo"], o["texto"], aviso])
	_esperando_tecla = true
	var escolhido: int = await _tecla_escolhida
	_esperando_tecla = false
	return escolhido


func _unhandled_input(event: InputEvent) -> void:
	if not _esperando_tecla:
		return
	for i in 4:
		if event.is_action_pressed("escolha_%d" % (i + 1)):
			_tecla_escolhida.emit(i)
			get_viewport().set_input_as_handled()
			return
