class_name HubEventos
extends Node
## [K8] Sequências do hub: intro do ECO na primeira chegada e "volta" quando o
## jogador chega com uma chave ainda não encaixada na porta.
##
## Ganchos opcionais (só são chamados se existirem, então funciona antes do K1 ao K5):
##   porta.encaixar(fase)        -> K3 (Tiago): anima a chave entrando na fechadura
##   filtro_cor.animar_zona(fase)-> K1 (Tiago): zona passa de cinza para colorida
##   hud.piscar_slot(fase)       -> K4 (Artur): slot da chave pisca no HUD
##   portais[fase + 1].acender() -> K2 (Tiago): o próximo portal acende
## Falas: data/hub/falas_hub.json (K5, Artur) por cima de FALAS_PADRAO.
## Uso: filho da cena do hub; chame verificar() ao entrar no hub (ou deixe auto_iniciar).

signal sequencia_terminou

const CAMINHO_FALAS: String = "res://data/hub/falas_hub.json"

# Provisório: o K5 (falas_hub.json) substitui qualquer chave que ele trouxer.
const FALAS_PADRAO: Dictionary = {
	"intro": [
		"{nome}, você chegou. Eu sou o ECO, a voz que vai te guiar.",
		"Este laboratório é a base: daqui você viaja pelo tempo.",
	],
	"hub": [
		"Cada portal leva a uma época. Comece pelo primeiro.",
		"Traga de lá uma chave e encaixe na porta de saída.",
	],
	"volta": {
		"0": ["A primeira chave encaixou. A cor voltou para esta zona."],
		"1": ["Segunda chave encaixada. O hub está ficando vivo de novo."],
		"2": ["Terceira chave encaixada. Falta só mais uma época."],
		"3": ["Todas as chaves no lugar. A porta está pronta."],
	},
}

@export var jogador: Player
@export var posicao_porta: Node2D
@export var porta: Node
@export var filtro_cor: Node
@export var hud: Node
@export var portais: Array[Node] = []
@export var auto_iniciar: bool = true
@export var duracao_camera: float = 1.5

var _ocupado: bool = false
var _falas: Dictionary = {}


func _ready() -> void:
	_falas = _carregar_falas()
	if jogador == null:
		var pai: Variant = get_parent().get("jogador")
		if pai is Player:
			jogador = pai
	if auto_iniciar:
		await get_tree().create_timer(0.6).timeout
		await verificar()


func esta_ocupado() -> bool:
	return _ocupado


# Roda a intro (se ainda não foi vista) e depois uma sequência por chave pendente.
func verificar() -> void:
	if _ocupado:
		return
	_ocupado = true
	if not GameState.intro_vista:
		await _intro()
	var fase: int = GameState.chave_pendente()
	while fase != -1:
		await _sequencia_volta(fase)
		fase = GameState.chave_pendente()
	_ocupado = false
	sequencia_terminou.emit()


func _intro() -> void:
	_travar(true)
	await _falar(_linhas("intro"))
	await _falar(_linhas("hub"))
	GameState.intro_vista = true
	_travar(false)


func _sequencia_volta(fase: int) -> void:
	_travar(true)
	var camera: Camera2D = null
	if jogador != null:
		camera = jogador.get_node_or_null("Camera2D") as Camera2D
	if camera != null and posicao_porta != null:
		await CameraBezier.mover_para(camera, posicao_porta.global_position, duracao_camera)

	await _chamar(porta, "encaixar", [fase])
	GameState.encaixar_chave(fase)  # idempotente; garante que o laço do verificar() avança
	await _chamar(filtro_cor, "animar_zona", [fase])
	await _chamar(hud, "piscar_slot", [fase])
	var proximo: int = fase + 1
	if proximo < GameState.TOTAL_FASES and proximo < portais.size():
		await _chamar(portais[proximo], "acender")
	await _falar(_linhas("volta", fase))

	if camera != null:
		await CameraBezier.voltar_ao_jogador(camera, duracao_camera)
	_travar(false)


func _travar(travar: bool) -> void:
	if jogador != null:
		jogador.pode_mover = not travar


func _chamar(alvo: Node, metodo: String, args: Array = []) -> void:
	if alvo != null and is_instance_valid(alvo) and alvo.has_method(metodo):
		await alvo.callv(metodo, args)


func _falar(linhas: Array) -> void:
	if not linhas.is_empty():
		await Mensagem.eco(linhas)


func _linhas(grupo: String, fase: int = -1) -> Array:
	var v: Variant = _falas.get(grupo, [])
	if fase >= 0 and v is Dictionary:
		v = v.get(str(fase), [])
	var saida: Array = []
	if v is Array:
		for linha in v:
			saida.append(str(linha).replace("{nome}", _nome()))
	return saida


func _nome() -> String:
	return GameState.nome_jogador if GameState.nome_jogador != "" else "Catalisador"


func _carregar_falas() -> Dictionary:
	var falas: Dictionary = FALAS_PADRAO.duplicate(true)
	if not FileAccess.file_exists(CAMINHO_FALAS):
		return falas
	var lido: Variant = JSON.parse_string(FileAccess.get_file_as_string(CAMINHO_FALAS))
	if lido is Dictionary:
		for chave in lido:
			falas[chave] = lido[chave]
	else:
		push_warning("falas_hub.json inválido; usando as falas padrão.")
	return falas
