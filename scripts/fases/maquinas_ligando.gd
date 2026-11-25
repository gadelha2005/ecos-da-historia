class_name MaquinasLigando
extends Node
## [L7] As máquinas do loteamento ligam de tempos em tempos e esquentam a negociação (N3.1 e N3.R).
## Usa a AgendaEventos (min-heap) filha: a cada `intervalo` segundos, a tensão da fase sobe
## `aumento` pontos e o ECO avisa. Se a tensão chega a 100, emite negociacao_rompeu.
## Uma conversa aprovada acalma o canteiro e adia a próxima vez (adiar()).
## Enquanto uma mensagem ou conversa está aberta, o evento espera alguns segundos.

signal maquinas_ligaram(tensao: int)
signal negociacao_rompeu

@export var intervalo: float = 90.0
@export var aumento: int = 10
## Desligue nos testes para o relógio não atrapalhar.
@export var ativa: bool = true

const ESPERA_MENSAGEM: float = 3.0
const AVISOS: Array[String] = [
	"As máquinas ligaram de novo do outro lado da cerca. O barulho deixa todo mundo mais nervoso.",
	"Ronco de trator perto da lagoa. A tensão subiu. Converse com calma para acalmar os dois lados.",
	"Um caminhão chegou ao canteiro. Se a tensão chegar ao máximo, a negociação rompe.",
]

var _geracao: int = 0
var _vezes: int = 0

@onready var agenda: AgendaEventos = $AgendaEventos


func _ready() -> void:
	if ativa:
		_agendar(intervalo)


## Empurra a próxima vez das máquinas para daqui a um intervalo inteiro.
func adiar() -> void:
	if ativa:
		_agendar(intervalo)


func _agendar(daqui: float) -> void:
	_geracao += 1
	var g := _geracao
	agenda.agendar(agenda.tempo_atual + daqui, "maquinas", func() -> void: _ligar(g))


func _ligar(geracao: int) -> void:
	if geracao != _geracao:
		return  # agendamento antigo, já foi adiado
	var mensagem := get_node_or_null("/root/Mensagem")
	if _jogador_ocupado() or (mensagem and mensagem.esta_aberta()):
		_agendar(ESPERA_MENSAGEM)
		return
	GameState.tensao_fase = clampi(GameState.tensao_fase + aumento, 0, 100)
	DialogoManager.tensao_inicial = GameState.tensao_fase
	maquinas_ligaram.emit(GameState.tensao_fase)
	if GameState.tensao_fase >= 100:
		negociacao_rompeu.emit()
		return
	_agendar(intervalo)
	if mensagem:
		_vezes += 1
		await mensagem.eco([AVISOS[(_vezes - 1) % AVISOS.size()]])


## Em conversa, na mesa ou lendo o ECO o jogador fica parado: as máquinas esperam.
func _jogador_ocupado() -> bool:
	for j in get_tree().get_nodes_in_group("jogador"):
		if not j.get("pode_mover"):
			return true
	return false
