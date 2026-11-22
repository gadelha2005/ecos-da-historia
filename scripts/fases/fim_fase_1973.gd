class_name FimFase1973
extends Node
## [M8] Fim da fase 1973 (N2.6 e N2.7), no mesmo formato do I8:
## fechamento curto → Chave da Cultura (GameState.dar_chave(FASE_1973)) → card "Você sabia?"
## → volta ao hub no Spawn_Portal1973. No hub, a chave encaixa na 2ª fechadura, a Zona_Cultura
## ganha cor e o portal de 1979 abre (portal_liberado(2)).
## Quem chama concluir() é a fase_1973.gd, depois que a planta da Mostra (M5) é aprovada.

signal fase_concluida

const CAMINHO_TEXTOS: String = "res://data/textos/fim_fase_1973.json"
const CENA_CARD: String = "res://scenes/ui/card_saber.tscn"
const CENA_HUB: String = "res://scenes/hub/hub.tscn"
const SPAWN_HUB: String = "Spawn_Portal1973"
const ICONE_CHAVE: Texture2D = preload("res://assets/sprites/hub/chaves/chave_cultura.png")

var _concluindo: bool = false


func concluir() -> void:
	if _concluindo:
		return
	_concluindo = true
	for jogador in get_tree().get_nodes_in_group("jogador"):
		jogador.set("pode_mover", false)

	var textos := _carregar_textos()
	var mensagem := get_node_or_null("/root/Mensagem")
	for fala in textos.get("fechamento", []):
		var linha := str(fala.get("texto", "")).replace("{nome}", _nome_jogador())
		if mensagem:
			await mensagem.mostrar([linha], str(fala.get("falante", "")))

	GameState.dar_chave(GameState.FASE_1973)

	var card: CardSaber = load(CENA_CARD).instantiate()
	get_tree().root.add_child(card)
	await card.mostrar(textos.get("saber", {}), ICONE_CHAVE, str(textos.get("chave", "")))

	fase_concluida.emit()
	SceneManager.trocar_cena(CENA_HUB, SPAWN_HUB)


func _nome_jogador() -> String:
	return GameState.nome_jogador if GameState.nome_jogador != "" else "Catalisador"


func _carregar_textos() -> Dictionary:
	var dados: Variant = JSON.parse_string(FileAccess.get_file_as_string(CAMINHO_TEXTOS))
	if typeof(dados) != TYPE_DICTIONARY:
		push_error("JSON inválido em " + CAMINHO_TEXTOS)
		return {}
	return dados
