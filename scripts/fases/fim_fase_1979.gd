class_name FimFase1979
extends Node
## [L9] Fim da fase 1979 (N3.7 e N3.8): fechamento → Chave do Meio Ambiente
## (GameState.dar_chave(FASE_1979)) → card "Você sabia?" → volta ao hub no Spawn_Portal1979.
## No hub a chave encaixa na 3ª fechadura, a zona da natureza ganha cor e o portal de 1982 abre (N3.9).
## Quem chama concluir() é a fase_1979.gd, depois que a mesa de acordo (L6) é aprovada.

signal fase_concluida

const CAMINHO_TEXTOS: String = "res://data/textos/fim_fase_1979.json"
const CENA_CARD: String = "res://scenes/ui/card_saber.tscn"
const CENA_HUB: String = "res://scenes/hub/hub.tscn"
const SPAWN_HUB: String = "Spawn_Portal1979"
const ICONE_CHAVE: Texture2D = preload("res://assets/sprites/hub/chaves/chave_ambiente.png")

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

	GameState.dar_chave(GameState.FASE_1979)

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
