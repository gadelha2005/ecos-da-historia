class_name FimFase1904
extends Node
## [I8] Fim da fase 1904.
## concluir(): cena curta de fechamento (N1.6) → Chave da Saúde
## (GameState.dar_chave(GameState.FASE_1904)) → card "Você sabia?" (N1.7) → volta ao hub.
## No hub, a Fase 3 (K0/K1) cuida do resto: a chave fica pendente (GameState.chave_pendente()),
## é encaixada na porta e só então a Zona_Saude ganha cor (GameState.cor_zona).
## O portal de 1973 abre sozinho por portal_liberado(1).
##
## Coloque este nó na cena da fase. Com `concluir_ao_aprovar_ultimo` ligado, ele escuta
## os moradores (grupo "moradores", sinal conversa_terminou do I2) e conclui sozinho
## quando o último for aprovado. Também dá pra chamar concluir() direto.

signal fase_concluida

const CAMINHO_TEXTOS: String = "res://data/textos/fim_fase_1904.json"
const CENA_CARD: String = "res://scenes/ui/card_saber.tscn"
const CENA_HUB: String = "res://scenes/hub/hub.tscn"
const SPAWN_HUB: String = "Spawn_Portal1904"
const ICONE_CHAVE: Texture2D = preload("res://assets/sprites/fase1904/chave_saude.png")

## Conclui sozinho quando o último morador for aprovado.
@export var concluir_ao_aprovar_ultimo: bool = true

var _concluindo: bool = false


func _ready() -> void:
	if concluir_ao_aprovar_ultimo:
		_escutar_moradores.call_deferred()  # espera os moradores da cena entrarem na árvore


func _escutar_moradores() -> void:
	for morador in get_tree().get_nodes_in_group("moradores"):
		if morador.has_signal("conversa_terminou"):
			morador.conversa_terminou.connect(_on_conversa_terminou)


func _on_conversa_terminou(_morador_id: String, aprovado: bool) -> void:
	if aprovado and todos_concluidos():
		# espera a conversa devolver o controle ao jogador antes de começar o fechamento
		concluir.call_deferred()


static func todos_concluidos() -> bool:
	return GameState.moradores_concluidos >= GameState.MORADORES.size()


func concluir() -> void:
	if _concluindo:
		return
	_concluindo = true
	_travar_jogador()

	var textos := _carregar_textos()
	await _cena_fechamento(textos.get("fechamento", []))

	GameState.dar_chave(GameState.FASE_1904)

	var card: CardSaber = load(CENA_CARD).instantiate()
	get_tree().root.add_child(card)
	await card.mostrar(textos.get("saber", {}), ICONE_CHAVE, str(textos.get("chave", "")))

	fase_concluida.emit()
	SceneManager.trocar_cena(CENA_HUB, SPAWN_HUB)


func _cena_fechamento(falas: Array) -> void:
	var mensagem := get_node_or_null("/root/Mensagem")
	for fala in falas:
		var falante := str(fala.get("falante", ""))
		var linha := str(fala.get("texto", "")).replace("{nome}", _nome_jogador())
		if mensagem:
			await mensagem.mostrar([linha], falante)
		else:
			print("%s: %s" % [falante, linha])


func _nome_jogador() -> String:
	return GameState.nome_jogador if GameState.nome_jogador != "" else "Catalisador"


func _travar_jogador() -> void:
	for jogador in get_tree().get_nodes_in_group("jogador"):
		jogador.set("pode_mover", false)


func _carregar_textos() -> Dictionary:
	if not FileAccess.file_exists(CAMINHO_TEXTOS):
		push_error("Textos não encontrados: " + CAMINHO_TEXTOS)
		return {}
	var dados: Variant = JSON.parse_string(FileAccess.get_file_as_string(CAMINHO_TEXTOS))
	if typeof(dados) != TYPE_DICTIONARY:
		push_error("JSON inválido em " + CAMINHO_TEXTOS)
		return {}
	return dados
